#!/bin/sh

#
# Wait for backend (AEM_HOST) to be available
# 
if [ -z "${AEM_HOST}" -o -z "${AEM_PORT}" ]; then
  echo "AEM_HOST and/or AEM_PORT are undefined, stop"
  exit 2
fi

# Support the AEM_HOST_PATTERN variable
if [ -n "${AEM_HOST_PATTERN}" ]; then
  export AEM_HOST="$(printf $AEM_HOST_PATTERN ${HOSTNAME##*-})"
fi

echo "Waiting until ${AEM_HOST} is available"
until [ -n "${AEM_IP}" ]; do
  AEM_IP=$(getent hosts "${AEM_HOST}" | cut -f1 -d' ')
done

echo "${AEM_HOST} resolves to ${AEM_IP}"
export AEM_IP

if [ "${SKIP_BACKEND_WAIT}" = "true" ]; then
  echo "Waiting until port ${AEM_PORT} on ${AEM_HOST} skipped due to SKIP_BACKEND_WAIT variable set"
else
  portTimeoutSeconds=1
  portSleepSeconds=5
  echo "Waiting until port ${AEM_PORT} on ${AEM_HOST} is available (with timeout of ${portTimeoutSeconds}s)"
  while [ true ]; do
    nc -z -w $portTimeoutSeconds "${AEM_HOST}" "${AEM_PORT}"
    ncExitStatus=$?
    if [ $ncExitStatus -eq 0 ]; then
      break;
    fi
    echo "Sleeping for ${portSleepSeconds}s to wait until port ${AEM_PORT} on ${AEM_HOST} is available"
    sleep $portSleepSeconds
  done
  echo "Port ${AEM_PORT} on ${AEM_HOST} is available"
fi

echo "${AEM_HOST}" > /tmp/aem_host
echo "${AEM_IP}" > /tmp/aem_ip