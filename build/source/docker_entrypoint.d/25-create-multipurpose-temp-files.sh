#!/bin/sh

#
# Specify default Apache multipurpose temp file count if none is set
#
if [ -z "${APACHE_MULTIPURPOSE_TEMP_FILE_COUNT}" ]; then
  APACHE_MULTIPURPOSE_TEMP_FILE_COUNT=10
else
  echo "Detected Apache multipurpose temp file count: ${APACHE_MULTIPURPOSE_TEMP_FILE_COUNT}"
fi

cat >> /usr/sbin/envvars <<EOF
export APACHE_MULTIPURPOSE_TEMP_FILE_COUNT="${APACHE_MULTIPURPOSE_TEMP_FILE_COUNT}"
EOF

TEMP_DIR="/tmp"
TEMP_FILE_NAME_PREFIX="apache-multipurpose-temp-file-"
ENV_VAR_NAME_PREFIX="APACHE_MULTIPURPOSE_TEMP_FILE_"

mkdir -p "${TEMP_DIR}"

idx=0
while [ "$idx" -lt "${APACHE_MULTIPURPOSE_TEMP_FILE_COUNT}" ]; do

  TEMP_FILE_PATH="${TEMP_DIR}/${TEMP_FILE_NAME_PREFIX}${idx}"
  ENV_VAR_NAME="${ENV_VAR_NAME_PREFIX}${idx}"
  echo "Creating Apache multipurpose temp file ${ENV_VAR_NAME}=${TEMP_FILE_PATH}"
  touch "${TEMP_FILE_PATH}"
  chown "${APACHE_USER}:${APACHE_GROUP}" "${TEMP_FILE_PATH}"
  chmod o-rwx "${TEMP_FILE_PATH}"

  cat >> /usr/sbin/envvars <<EOF
export ${ENV_VAR_NAME}="${TEMP_FILE_PATH}"
EOF

  idx=$(( idx + 1 ))

done
