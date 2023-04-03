#!/bin/sh

#
# Mkdir all virtual host document roots with correct ownership
# 

VHOSTS_DIR=${APACHE_PREFIX}/conf.d/enabled_vhosts

len=$(echo -n ${APACHE_DOCROOT} | wc -m)

for vhost in "${VHOSTS_DIR}"/*.vhost; do
  if [ "$vhost" = "${VHOSTS_DIR}/*.vhost" ]; then
    echo "No virtual hosts enabled in ${VHOSTS_DIR}"
    exit 2
  fi

  #                    clean-up for UNICODE No-Break Space (NBSP)
  docroot=$(cat "${vhost}" | busybox tr '[\x00\xA0\xC2]' ' ' | sed -nE 's/^[[:space:]]*DocumentRoot[[:space:]]+([^[:space:]]+)[[:space:]]*/\1/p')

  if [ "$docroot" = "" ]; then
    echo "${vhost}: empty docroot skipping."
    continue
  fi

  # Assume that there may be multiple DocumentRoot definitions in the same configuration
  for docline in ${docroot//\\n/ } ; do
    docline=$(eval "echo ${docline}")

    prefix=$(echo "$docline" | cut -c -"$len")
    if [ "$prefix" != "${APACHE_DOCROOT}" ]; then
      echo "$vhost: DocumentRoot not underneath ${APACHE_DOCROOT}: $docroot"
      exit 2
    fi

    mkdir -p "$docline"
    chown "${APACHE_USER}:${APACHE_GROUP}" "$docline"
    chmod o-rwx "$docline"
  done
done
chown -R "${APACHE_USER}:${APACHE_GROUP}" "${APACHE_DOCROOT}"
