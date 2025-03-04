#!/bin/bash
#
# Script to run docker dispatcher image to detect changes in immutable config files
# or to extract immutable config files from the image into a folder.
#
# Usage: docker_immutability_check.sh config-folder [mode: {check|extract}]
#

usage() {
    cat <<EOF >& 1
Usage: $0 config-folder [mode: {check|extract}]

Examples:
  # Use config folder "src" (assuming default "check" mode) for immutable files check
  $0 src
  or explicitly giving the "check" mode
  $0 src check
  # Use config folder "src" as a destination to extract immutable files into it
  $0 src extract

Environment variables available:
  IMMUTABLE_FILES_UPDATE:     controls whether immutable files should be updated or not.
                              Valid values are true or false (default is true)
EOF
    exit 1
}

error() {
    echo >&2 "** error: $1"
    exit 2
}

warn() {
    echo >&2 "** warning: $1"
}

info() {
    echo "** info: $1"
}

[ $# -eq 1 ] || [ $# -eq 2 ] || usage

folder=$1
shift

mode=$1

if [ "$mode" == "" ]; then
	echo "empty mode param, assuming mode = 'check'"
	mode="check"
else
	if [ "$mode" != "check" ] && [ "$mode" != "extract" ]; then
		error "mode '$mode' is neither 'check' nor 'extract'"
	fi
fi

echo "running in '${mode}' mode"

command -v docker >/dev/null 2>&1 || error "docker not found, aborting."

# Make folder path absolute for docker volume mount
first=$(echo "${folder}" | sed 's/\(.\).*/\1/')
if [ "${first}" != "/" ]
then
    folder=${PWD}/${folder}
fi

[ -d "${folder}" ] || error "config folder not found: ${folder}"

repo=adobe
image=aem-cs/dispatcher-publish
version=2.0.235
imageurl="${repo}/${image}:${version}"

if [ -z "$(docker images -q "${imageurl}" 2> /dev/null)" ]; then
    echo "Required image not found, trying to load from archive..."
    # Use arm64 image for e.g. M1 Macbooks
    arch=$(uname -m)
    if [[ "$arch" == "arm64" || "$arch" == "aarch64" ]]; then
        file=$(dirname "$0")/../lib/dispatcher-publish-arm64.tar.gz
    else
        file=$(dirname "$0")/../lib/dispatcher-publish-amd64.tar.gz
    fi
    [ -f "${file}" ] || error "unable to find archive at expected location: $file"
    gunzip -c "${file}" | docker load
    [ -n "$(docker images -q "${imageurl}" 2> /dev/null)" ] || error "required image still not found: $imageurl"
fi

scriptDir="$(cd -P "$(dirname "$0")" && pwd -P)"

configVolumeMountMode="rw"
if [ "$mode" == "check" ]; then
    configVolumeMountMode="ro"
fi

docker run --rm \
    -v "${folder}":/etc/httpd-actual:${configVolumeMountMode} \
    -v "${scriptDir}"/../lib/immutability_check.sh:/usr/sbin/immutability_check.sh:ro \
    --entrypoint /bin/sh "${imageurl}" /usr/sbin/immutability_check.sh /etc/httpd/immutable.files.txt /etc/httpd-actual ${mode}
exitcode=$?

if [[ ${exitcode} != 0 ]]; then
    if [ -z "${IMMUTABLE_FILES_UPDATE}" ] || [ "${IMMUTABLE_FILES_UPDATE}" == "true" ]; then
        info "Immutable files were changed. Force update on immutable files is enabled."

        while true; do
            read -p "Do you want to update the immutable files? (yes/no) " answer
            case $answer in
                [Yy]* )
                    ${scriptDir}/update_maven.sh "${folder}"
                    info "User is advised to re-run the validation of immutable files again."
                    exit 0;;
                [Nn]* )
                    exit 0;;
                * )
                    echo "Please answer yes or no.";;
            esac
        done
    fi
    if [ "${IMMUTABLE_FILES_UPDATE}" == "false" ]; then
        info "Immutable files were changed."
        exit ${exitcode}
    fi
else
    exit 0
fi
