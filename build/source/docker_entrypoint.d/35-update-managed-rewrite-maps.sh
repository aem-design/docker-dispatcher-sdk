#!/bin/sh

#
# Update managed rewrite maps - required for dispatcher config referring to those maps to start
#

MANAGED_REWRITE_MAPS_DESCRIPTOR=${APACHE_PREFIX}/opt-in/managed-rewrite-maps.yaml
MANAGED_REWRITE_MAPS_LOG=${APACHE_PREFIX}/logs/httpd_managed_rewrite_maps.log

TEMP_DIR=/tmp
REWRITE_MAP_DIR=${TEMP_DIR}/rewrites
# file used by IfFile directive
READINESS_MARKER_FILE=${REWRITE_MAP_DIR}/ready

as_apache() {
  su-exec "${APACHE_USER}:${APACHE_GROUP}" $*
}

debug_msg() {
  # only subset of formatting flags is supported in busybox's date - https://man7.org/linux/man-pages/man3/strftime.3.html
  formatted_date="$(date '+%a %b %d %H:%M:%S.%6N %Y')"
  module_name="managed_rewrite_maps"
  log_level="debug"
  pid="$$"

  # based on https://httpd.apache.org/docs/2.4/mod/core.html#errorlogformat
  echo "[${formatted_date}] [${module_name}:${log_level}] [pid ${pid}] $*" | tee -a "${MANAGED_REWRITE_MAPS_LOG}"
}

debug_cmd() {
  cmd_output=$($* 2>&1 | tr '\n' '\t' || true)
  debug_msg "out+err: $cmd_output"
}

# check if file already exists and its TTL is not yet exceeded - then skip
# params: <file> <ttl>
should_regenerate() {

  if [ ! -f "$1" ]; then
    debug_msg "no map file '$1' exists yet - will generate for the first time"
    return 0
  fi

  debug_msg "checking time since last modification of '$1' > ttl '$2' seconds"

  # %Y Time of last modification as seconds since Epoch
  mtime=$(stat -c "%Y" "$1")
  nowtime=$(date +"%s")
  debug_msg "nowtime = '$nowtime' mtime = '$mtime' seconds since epoch for '$1' file"

  secs_since_last_mod=$(( $nowtime - $mtime ))
  debug_msg "seconds since last modification of '$1' file = '$secs_since_last_mod'"

  if [ "$secs_since_last_mod" -gt "$2" ]; then
    debug_msg "TTL '$ttl' exceeded - regenerating map for '$1' file"
    return 0
  else
    secs_left_to_exceed_ttl=$(( $2 - $secs_since_last_mod ))
    debug_msg "'$secs_left_to_exceed_ttl' seconds left to exceed ttl = '$ttl' for '$1' file"
    return 1
  fi
}

generate_map_file() {
  debug_msg "using file '${TEMP_FILE}' for '${name}' map"
  debug_cmd ls -al "${TEMP_FILE}"

  max_line_length=$(wc --max-line-length ${TEMP_FILE})
  debug_msg "max line length in '${TEMP_FILE}' for '${name}' map: ${max_line_length}"

  initial_line_count=$(cat ${TEMP_FILE} | wc -l | awk '{ print $1 }')
  debug_msg "initial line count in '${TEMP_FILE}' for '${name}' map: ${initial_line_count}"

  long_line_count=$(cat ${TEMP_FILE} | awk 'length>1024' | wc -l | awk '{ print $1 }')
  debug_msg "line count exceeding 1024 limit in '${TEMP_FILE}' for '${name}' map: ${long_line_count}"

  TEMP_FINAL_FILE=$(as_apache mktemp)

  if [ "$long_line_count" -gt "0" ];
  then
    debug_msg "map '${name}' file '${TEMP_FILE}' has lines longer than 1024 limit - needs filtering"
    cat ${TEMP_FILE} | awk 'length<=1024' > ${TEMP_FINAL_FILE}
  else
    debug_msg "map '${name}' file '${TEMP_FILE}' lines are within 1024 length limit - filtering not needed"
    as_apache cp ${TEMP_FILE} ${TEMP_FINAL_FILE}
  fi

  final_line_count=$(cat ${TEMP_FINAL_FILE} | wc -l | awk '{ print $1 }')
  debug_msg "final line count in '${TEMP_FINAL_FILE}' for '${name}' map: ${final_line_count}"

  debug_cmd as_apache httxt2dbm -i ${TEMP_FINAL_FILE} -o ${TEMP_DIR}/${name} -f SDBM

  debug_cmd as_apache mv -v ${TEMP_DIR}/${name}.* ${REWRITE_MAP_DIR}
  debug_msg "generated map under '${REWRITE_MAP_DIR}' for '${name}' map"
  debug_cmd ls -al "${REWRITE_MAP_DIR}/${name}".*
  as_apache rm ${TEMP_FINAL_FILE}
  as_apache rm ${TEMP_FILE}
  debug_msg "map configured in '${REWRITE_MAP_DIR}/${name}.*' files"
}

update_map() {
  TEMP_FILE=$(as_apache mktemp)
  chmod 644 "${TEMP_FILE}"
  resp=$(curl -w "%{http_code}" --silent --location --show-error --fail "http://${AEM_HOST}:${AEM_PORT}${path}" -o "${TEMP_FILE}" --retry 10 --retry-max-time 60 --retry-connrefused || true)
  if [ $resp -eq 200 ]; then
    debug_msg "map '$name' received from path '$path'"
    generate_map_file
  else
    as_apache rm -f "${TEMP_FILE}"
    debug_msg "Unable to download map '$name' from path '$path' - response status code '$resp'"
    if [ "$wait" = "false" ]; then
      debug_msg "Not waiting for map '$name' data - generating empty map instead due to param wait = '$wait'"
      as_apache touch "${TEMP_FILE}"
      generate_map_file
    else
      debug_msg "NOT generating empty map due to lack of map '$name' data and param wait = '$wait'"
    fi
  fi
}

check_is_probe_ok() {
  if [ "$MANAGED_REWRITE_MAPS_PROBE_CHECK_SKIP" = "true" ]; then
    debug_msg "MANAGED_REWRITE_MAPS_PROBE_CHECK_SKIP is true - ignoring probe check and assuming it's OK"
    return 0
  fi

  if [ -z "$probePath" ]; then
    debug_msg "probe not set - ignoring probe check and assuming it's OK"
    return 0
  fi

  debug_msg "checking if probe '$probePath' is 200 OK"

  resp=$(curl -w "%{http_code}" --silent --location --show-error --fail "http://${AEM_HOST}:${AEM_PORT}${probePath}" -o /dev/null --retry 20 --retry-max-time 120 --retry-connrefused --retry-all-errors || true)
  if [ $resp -eq 200 ]; then
    debug_msg "probe '$probePath' for map '$name' is OK"
    return 0
  else
    debug_msg "probe '$probePath' for map '$name' is NOT OK !!! - resp status code = '$resp'"
    return 1
  fi
}

process_maps() {
  yq -r '.maps | length' < "$MANAGED_REWRITE_MAPS_DESCRIPTOR" | while read -r mapLength; do
    debug_msg "map count = $mapLength"
  done

  as_apache mkdir -p "${REWRITE_MAP_DIR}"
  yq -o=json '.maps[]' < "$MANAGED_REWRITE_MAPS_DESCRIPTOR" \
  | jq -r -c  '. | [.name, .path, .wait // false, .ttl // 300, .probePath // "/system/probes/health"] | @tsv' \
  | while read -r name path wait ttl probePath; do
    debug_msg "mapping '$name' from path '$path' with params wait = '$wait' and ttl = '$ttl' and probePath = '$probePath'"

    should_regenerate "${REWRITE_MAP_DIR}/${name}.pag" $ttl
    if [ $? -eq 0 ]; then
      check_is_probe_ok
      if [ $? -eq 0 ]; then
        update_map
      else
        debug_msg "configured probe '$probePath' for map $name is NOT OK - won't proceed to fetch map data from unreliable source !!!"
      fi
    else
      debug_msg "ttl = '$ttl' not exceeded for previously generated map - will SKIP map '$name' regeneration for now"
    fi

  done
}

HTTPD_PID_FILE="${APACHE_RUN_DIR}/httpd.pid"

signal_map_data_readiness() {
  # map data readiness signalling - file used by IfFile directive
  if [[ -f ${READINESS_MARKER_FILE} ]]
  then
    debug_msg "Maps were already ready - no need to send signal again to reload httpd config"
  else
    as_apache touch ${READINESS_MARKER_FILE}
    # send SIGUSR1 to notify httpd that ready file exists (for IfFile-conditional configuration parts)
    if [[ -f ${HTTPD_PID_FILE} ]]
    then
      debug_msg "Using httpd PID from ${HTTPD_PID_FILE} for map data readiness signalling"
      kill -USR1 $(cat ${HTTPD_PID_FILE})
      debug_msg "Signal to reload httpd config sent due to map data readiness"
    else
      debug_msg "No httpd PID file found at ${HTTPD_PID_FILE} for map data readiness signalling"
    fi
  fi
}

if [ "$ENABLE_MANAGED_REWRITE_MAPS_FLAG" = "true" ]; then

  if [ "${SKIP_BACKEND_WAIT}" = "true" ]; then
    echo "Update managed rewrite maps from ${AEM_HOST}:${AEM_PORT} backend skipped due to SKIP_BACKEND_WAIT variable set"
  else

    as_apache touch "${MANAGED_REWRITE_MAPS_LOG}"

    # rewrite maps update enabled (to know if to monitor heartbeat)
    debug_msg "Managed rewrite maps check in progress"

    if [ -f ${MANAGED_REWRITE_MAPS_DESCRIPTOR} ]; then
      debug_msg "Managed rewrite maps configured in '${MANAGED_REWRITE_MAPS_DESCRIPTOR}'"
      process_maps || true

      # reaching here should be enough to claim maps are ready
      signal_map_data_readiness
    else
      debug_msg "No managed rewrite maps configured"
    fi

    # heartbeat notification
    debug_msg "Managed rewrite maps check DONE"

  fi
fi
