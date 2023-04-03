#!/bin/sh

if [ -z "${DISP_LOG_LEVEL}" ]; then
  DISP_LOG_LEVEL=warn
else
  DISP_LOG_LEVEL=$(echo "${DISP_LOG_LEVEL}" | tr '[:upper:]' '[:lower:]')
  case "${DISP_LOG_LEVEL}" in
    trace1 | debug | info | warn | error)
      ;;
    *)
      echo "Dispatcher log level defined unknown: ${DISP_LOG_LEVEL}"
      exit 2
      ;;
  esac
  echo "Detected dispatcher log level: ${DISP_LOG_LEVEL}"
fi

if [ -z "${REWRITE_LOG_LEVEL}" ]; then
  REWRITE_LOG_LEVEL=warn
else
  REWRITE_LOG_LEVEL=$(echo "${REWRITE_LOG_LEVEL}" | tr '[:upper:]' '[:lower:]')
  case "${REWRITE_LOG_LEVEL}" in
    trace[1-8] | debug | info | warn | error)
      ;;
    *)
      echo "Rewrite log level defined unknown: ${REWRITE_LOG_LEVEL}"
      exit 2
      ;;
  esac
  echo "Detected rewrite log level: ${REWRITE_LOG_LEVEL}"
fi

cat >> /usr/sbin/envvars <<EOF
export DISP_LOG_LEVEL="${DISP_LOG_LEVEL}"
export REWRITE_LOG_LEVEL="${REWRITE_LOG_LEVEL}"
EOF