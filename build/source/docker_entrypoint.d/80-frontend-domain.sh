#!/bin/sh

if [[ -e /mnt/dispatcher-sandbox/fcdc-workspace-sas ]]; then
  FRONTEND_URI_PREFIX="https://$(cat /mnt/osgisecrets/fcdc-workspace/accountName).blob.core.windows.net/$(cat /mnt/osgisecrets/fcdc-workspace/container)"
  FRONTEND_URI_SUFFIX="$(cat /mnt/dispatcher-sandbox/fcdc-workspace-sas)"

  cat >> /usr/sbin/envvars <<EOF
export FRONTEND_URI_PREFIX="${FRONTEND_URI_PREFIX}"
export FRONTEND_URI_SUFFIX="${FRONTEND_URI_SUFFIX}"
EOF
fi
