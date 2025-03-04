#!/bin/bash
#
# Script to run docker dispatcher image with dispatcher configs (in flexible mode)
#
# This script will automatically evaluate and reload changes in the source folder as soon as they are saved.
#
# Usage: docker_run_hot_reload.sh dump-folder aemhost:aemport localport [env]
#

scriptDir=$(dirname "$0")

HOT_RELOAD=true ${scriptDir}/docker_run.sh $@
