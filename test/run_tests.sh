#!/bin/bash
#
# The 'run' performs a simple test that verifies that STI image.
# The main focus is that the image prints out the base-usage properly.
#
# IMAGE_NAME specifies a name of the candidate image used for testing.
# The image has to be available before this script is executed.
#
export RENDERER_PORT=8081
export DISPATCHER_PORT=8080
export DISPATCHER_LOGLEVEL=1
IMAGE_NAME=${1:-aemdesign/dispatcher-sdk}
FLAG_DEBUG=${2:-true}
IP=$(which ip)
if [[ -z $IP ]]; then
    LOCAL_IP="localhost"
else
    LOCAL_IP=$($IP route | awk '/default/ { print $3 }')
fi

echo "Testing image ${IMAGE_NAME} ..."
echo "Local IP: ${LOCAL_IP}"
echo "Renderer Port: ${RENDERER_PORT}"
echo "Dispatcher Port: ${DISPATCHER_PORT}"
echo "Dispatcher Log Level: ${DISPATCHER_LOGLEVEL}"
echo "Debug: ${FLAG_DEBUG}"
# output current path
echo "Current Path: $(pwd)"


#debug(message,type[error,info,warning],newlinesiffix)
function debug {

    local DEFAULT_COLOR_WARN="\033[0;31;93m" #light yellow
    local DEFAULT_COLOR_ERROR="\033[0;31;91m" #light red
    local DEFAULT_COLOR_INFO="\033[0;31;94m" #light blue
    local DEFAULT_COLOR_DEFAULT="\033[0;31;92m" #light green
    local DEFAULT_COLOR_RESET="\033[0m" #light green

    COLOR_WARN="${COLOR_WARN:-$DEFAULT_COLOR_WARN}" #light yellow
    COLOR_ERROR="${COLOR_ERROR:-$DEFAULT_COLOR_ERROR}" #light red
    COLOR_INFO="${COLOR_INFO:-$DEFAULT_COLOR_INFO}" #light blue
    COLOR_DEFAULT="${COLOR_DEFAULT:-$DEFAULT_COLOR_DEFAULT}" #light green
    COLOR_RESET="${COLOR_RESET:-$DEFAULT_COLOR_RESET}" #light green

    LABEL_WARN="${LABEL_WARN:-*WARN*}"
    LABEL_ERROR="${LABEL_ERROR:-*ERROR*}"
    LABEL_INFO="${LABEL_INFO:-*INFO*}"
    LABEL_DEFAULT="${LABEL_DEFAULT:-}"


    COLOR_START="$COLOR_DEFAULT"
    COLOR_END="$COLOR_RESET"

    local TEXT="${1:-}"
    local TYPE="${2:-}"
    local LABEL_TEXT=""
    local TEXT_SUFFUX=""
    local NEWLINESUFFUX=$3

    if [ ! "$NEWLINESUFFUX" == "" ]; then
        TEXT_SUFFUX="$NEWLINESUFFUX"
    fi

    case $TYPE in
        ("error") COLOR_START="$COLOR_ERROR" LABEL_TEXT="$LABEL_ERROR " COLOR_END="$COLOR_END";;
        ("info") COLOR_START="$COLOR_INFO" LABEL_TEXT="$LABEL_INFO ";;
        ("warn") COLOR_START="$COLOR_WARN" LABEL_TEXT="$LABEL_WARN ";;
    esac


    if [ "$FLAG_DEBUG" == "true" ]; then

        local LABEL=""
        if [ "$FLAG_DEBUG_LABEL" == "true" ]; then
            LABEL=${LABEL_TEXT:-}
        fi

        TEXT="${TEXT//#d:/$COLOR_DEFAULT}"
        TEXT="${TEXT//#w:/$COLOR_WARN}"
        TEXT="${TEXT//#e:/$COLOR_ERROR}"
        TEXT="${TEXT//#i:/$COLOR_INFO}"
        TEXT="${TEXT//#r:/$COLOR_INFO}"

        echo -e "$COLOR_START$LABEL$TEXT$TEXT_SUFFUX$COLOR_END"
#        printf "$COLOR_START%s%s$COLOR_END$TEXT_SUFFUX" "$LABEL" "$TEXT"
    fi
}


printTitle() {
    echo -n ${1:-Test}
}
printLine() {
    echo ${1:-Test}
}
printResult() {
    debug "${1:-fail}" "${1:-fail}"
}
printDebug() {
    debug "$(printf '*%.0s' {1..100})" "error"
    echo ${1:-Test Failed}
    echo "${2:-No Output}"
    debug "$(printf '*%.0s' {1..100})" "error"
}

printSection() {
    debug "$(printf '*%.0s' {1..100})" "info"
    echo ${1:-Section}
    debug "$(printf '*%.0s' {1..100})" "info"
}

setup() {
	printLine "Starting Container"
  docker-compose up -d --force-recreate --build
}

showlog() {
  printSection "Dispatcher Author Log"
  docker logs test_dispatcher_author
  printSection "Dispatcher Publish Log"
  docker logs test_dispatcher_publish
}

teardown() {
	printLine "Remove Test containers"
	docker-compose down
}

test_docker_run_usage() {
	printLine "Testing 'docker run' usage"
	PATH_TO_CHECK="/content/aemdesign-showcase/au/en/component/details/generic-details.html"
	CHECK="${PATH_TO_CHECK}"
  TEST_PORT="${1}"

  printLine "Requesting page from container"

	OUTPUT=$(sleep 5 && curl -s "http://0.0.0.0:${TEST_PORT}${PATH_TO_CHECK}")

	if [[ "$OUTPUT" != *"$CHECK"* ]]; then
	    printResult "error"
	    printDebug "Image '${IMAGE_NAME}' test FAILED could not find ${CHECK} in output" "${OUTPUT}"
	    exit 1
    else
        printResult "success"
	fi


}

# setup
printLine "TEST CONFIGS"

test_docker_run_usage ${DISPATCHER_PORT}

printLine "SHOW LOGS"
showlog

# teardown
