FROM  alpine:latest

LABEL   maintainer="devops <devops@aem.design>" \
        version="4.3.3" \
        imagename="dispatcher-sdk" \
        test.command=" httpd -v | awk 'NR==1 {print $3}' | awk -F /  'NR==1 {print $2}'" \
        test.command.verify="2.4.6"

LABEL maintainer="devops <devops@aem.design>"

ARG APACHE_PREFIX="/etc/httpd"
ARG APACHE_DOCROOT="/mnt/var/www/html"
ARG APACHE_USER="apache"
ARG APACHE_GROUP="apache"
ARG APACHE_SERVER_ROOT="/var/www"
ARG APACHE_RUN_DIR="/run/apache2"
ARG AEM_HOST="localhost"
ARG AEM_PORT=4502
ARG VALIDATOR_BINARY="/usr/local/bin/validator"
ARG USER_DATA_DIR="/mnt/dev/src"

ENV APACHE_PREFIX="${APACHE_PREFIX}" \
    APACHE_DOCROOT="${APACHE_DOCROOT}" \
    APACHE_USER="${APACHE_USER}" \
    APACHE_GROUP="${APACHE_GROUP}" \
    APACHE_SERVER_ROOT="${APACHE_SERVER_ROOT}" \
    APACHE_RUN_DIR="${APACHE_RUN_DIR}" \
    DOCROOT="${APACHE_DOCROOT}" \
    VALIDATOR_BINARY="${VALIDATOR_BINARY}" \
    AEM_HOST="${AEM_HOST}" \
    AEM_PORT="${AEM_PORT}" \
    USER_DATA_DIR="${USER_DATA_DIR}"

# inslall apache
RUN   apk --no-cache add apache2 apache2-proxy apache2-ssl apache2-utils curl ed libxml2 inotify-tools su-exec bash unzip && \
      mkdir -p ${APACHE_PREFIX} && \
      mkdir -p ${APACHE_RUN_DIR} && \
      mkdir -p ${APACHE_DOCROOT} && \
      mkdir /scripts && \
      chown ${APACHE_USER}:${APACHE_GROUP} ${APACHE_DOCROOT}

# copy initial content
COPY  build/source /

# add symlinks for logs, modules and run
RUN   cd ${APACHE_PREFIX} && \
      ln -s ${APACHE_SERVER_ROOT}/logs .  && \
      ln -s ${APACHE_SERVER_ROOT}/modules .  && \
      ln -s ${APACHE_RUN_DIR} run  && \
      chown -R -L ${APACHE_USER}:${APACHE_GROUP} ${APACHE_SERVER_ROOT}/logs  && \
      chown -R -L ${APACHE_USER}:${APACHE_GROUP} /var/log  && \
      chown -R -L ${APACHE_USER}:${APACHE_GROUP} ${APACHE_SERVER_ROOT}/modules  && \
      chown -R -L ${APACHE_USER}:${APACHE_GROUP} ${APACHE_RUN_DIR} && \
      chmod +x /docker_entrypoint.sh

# add symlinks for default vhost and farm
RUN   cd ${APACHE_PREFIX}/conf.d/enabled_vhosts  && \
      ln -s ../available_vhosts/default.vhost default.vhost  && \
      cd ${APACHE_PREFIX}/conf.dispatcher.d/enabled_farms  && \
      ln -s ../available_farms/default.farm default.farm

# create httpd overlay layers
RUN   cd /etc/httpd  && \
      chmod +x /tmp/create-httpd-overlay-layers.sh  && \
      /tmp/create-httpd-overlay-layers.sh && \
      rm -f /tmp/create-httpd-overlay-layers.sh

# cleanup
RUN   rm -rf /var/www/localhost/cgi-bin

# copy dispatcher sdk
COPY  lib /usr/lib/dispatcher-sdk

# copy scripts
COPY  lib/dummy_gitinit_metadata.sh /docker_entrypoint.d/zzz-overwrite_gitinit_metadata.sh
COPY  lib/import_sdk_config.sh /docker_entrypoint.d/zzz-import-sdk-config.sh

EXPOSE  80

ENTRYPOINT ["/docker_entrypoint.sh"]
CMD ["/usr/sbin/httpd-foreground"]


VOLUME  ["${USER_DATA_DIR}"]
