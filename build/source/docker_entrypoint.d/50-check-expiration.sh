#!/bin/sh

#
# Specify default expiration time if none is set
#
if [ -z "${EXPIRATION_TIME}" ]; then
  EXPIRATION_TIME=300
else
  echo "Detected expiration time: ${EXPIRATION_TIME} seconds"
fi

cat >> /usr/sbin/envvars <<EOF
export EXPIRATION_TIME="${EXPIRATION_TIME}"
EOF
