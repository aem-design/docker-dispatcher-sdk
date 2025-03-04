#!/bin/sh

#
# Specify default setting if none set
#
if [ -z "${FORWARDED_HOST_SETTING}" ]; then
  FORWARDED_HOST_SETTING=Off
else
  echo "Detected forwarded host setting: ${FORWARDED_HOST_SETTING}"
  # Enabling X-Request-Id header logging due to forwarded host mode setting
  cat >> /usr/sbin/envvars <<EOF
export ENABLE_X_REQUEST_ID_LOGGING="true"
EOF
fi

cat >> /usr/sbin/envvars <<EOF
export FORWARDED_HOST_SETTING="${FORWARDED_HOST_SETTING}"
EOF