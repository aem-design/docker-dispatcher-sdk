#!/bin/sh

HTTPD_BASE_DIR=/etc/httpd
LAYERS_BASE_DIR=/etc/httpd-overlay

echo "${LAYERS_BASE_DIR} 0,1,2-layers creation from selected configs of ${HTTPD_BASE_DIR} started"

LAYER0_DIR=${LAYERS_BASE_DIR}/layer0-defaults
mkdir -p ${LAYER0_DIR}
find ${HTTPD_BASE_DIR} -type d -mindepth 1 -maxdepth 1 -print0 | xargs -I{} cp -r {} ${LAYER0_DIR}
rm ${LAYER0_DIR}/conf.d/enabled_vhosts/default.vhost
rm ${LAYER0_DIR}/conf.dispatcher.d/enabled_farms/default.farm
echo "layer0-defaults created in ${LAYER0_DIR}"

LAYER1_DIR=${LAYERS_BASE_DIR}/layer1-enabled
mkdir -p ${LAYER1_DIR}
cd ${HTTPD_BASE_DIR} && find -type l -name default.vhost -exec cp -a --parents {} ${LAYER1_DIR} \; && cd -
cd ${HTTPD_BASE_DIR} && find -type l -name default.farm -exec cp -a --parents {} ${LAYER1_DIR} \; && cd -
echo "layer1-enabled created in ${LAYER1_DIR}"

LAYER2_DIR=${LAYERS_BASE_DIR}/layer2-immutable
mkdir -p ${LAYER2_DIR}
for immutable in $(cat ${HTTPD_BASE_DIR}/immutable.files.txt); do
	mkdir -p ${LAYER2_DIR}/$(dirname $immutable);
	cp -v ${HTTPD_BASE_DIR}/$immutable ${LAYER2_DIR}/$immutable || exit 1;
done
sed 's/${AEM_IP}/{{ env.AEM_IP }}/' ${HTTPD_BASE_DIR}/conf.dispatcher.d/cache/default_invalidate.any > \
		${LAYER2_DIR}/conf.dispatcher.d/cache/default_invalidate.any.mustache
echo "layer2-immutable created in ${LAYER2_DIR}"
