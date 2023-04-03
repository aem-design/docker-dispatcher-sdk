#!/bin/sh
set -e

if [ -e "/tmp/aem_host" ] && [ -e "/tmp/aem_ip" ]; then
  AEM_HOST="$(cat "/tmp/aem_host")"
  AEM_IP="$(cat "/tmp/aem_ip")"
  CURRENT_AEM_IP=$(getent hosts "${AEM_HOST}" | cut -f1 -d' ')
  [ "${AEM_IP}" == "${CURRENT_AEM_IP}" ] || exit 1
fi

# Determine amount of disk space used for cache files (in percent)
USAGE=$(df -h ${APACHE_DOCROOT} | sed -En 's/.*([ 1][0-9 ][0-9])%.*/\1/p')
# Return bad response code when disk usage is 99% or more
[ ${USAGE} -lt 99 ]