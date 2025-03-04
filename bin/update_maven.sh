#!/bin/bash
#
# Script to update the pom.xml of an AEMaaCS project.
#
# Usage: update_maven.sh config-folder [--printOnly]
#

usage() {
    cat <<EOF >& 1
Usage: $0 config-folder [--printOnly]

Examples:
  # Use config folder "src" for overwriting immutable files and adapting pom.xml file.
  $0 src
  # Use config folder "src" for overwriting immutable files and printing out new checksums.
  $0 src --printOnly

EOF
    exit 1
}

dispatcherFolder="$1"

if [[ -z "$dispatcherFolder" ]]; then
    echo "A valid dispatcher configuration folder has to be specified!"
    usage
    exit 1
fi

vmode="--overwrite"
if [[ -n "$2" ]]; then
    if [[ "$2" == "--printOnly" ]]; then
        vmode="--printOnly"
    elif [[ "$2" == "--overwrite" ]]; then
        vmode="--overwrite"
    else
        echo "Unknown second parameter! Can be '--overwrite' or '-printOnly'"
        usage
        exit 1
    fi
fi

echo "Updating dispatcher configuration at folder ${dispatcherFolder}"

binFolder=$(dirname "$0")
${binFolder}/docker_immutability_check.sh ${dispatcherFolder} extract

command -v docker >/dev/null 2>&1 || error "docker not found, aborting."

repo=adobe
image=aem-cs/dispatcher-publish
version=2.0.235
imageurl="${repo}/${image}:${version}"

if [ -z "$(docker images -q "${imageurl}" 2> /dev/null)" ]; then
    echo "Required image not found, trying to load from archive..."
    # Use arm64 image for e.g. M1 Macbooks
    arch=$(uname -m)
    if [[ "$arch" == "arm64" || "$arch" == "aarch64" ]]; then
        file=${binFolder}/../lib/dispatcher-publish-arm64.tar.gz
    else
        file=${binFolder}/../lib/dispatcher-publish-amd64.tar.gz
    fi
    [ -f "${file}" ] || error "unable to find archive at expected location: $file"
    gunzip -c "${file}" | docker load
    [ -n "$(docker images -q "${imageurl}" 2> /dev/null)" ] || error "required image still not found: $imageurl"
fi

id=$(docker create ${imageurl})
docker cp $id:/etc/httpd/immutable.files.txt immutable.files.txt
docker rm -v $id

# Run validator in mvn mode
${binFolder}/validator mvn immutable.files.txt ${dispatcherFolder} ${vmode}

rm immutable.files.txt
