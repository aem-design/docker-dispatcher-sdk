#!/bin/sh

#
# Display image version
#
echo "${IMAGE_NAME}" | awk -F: '{print "Image version: "$2}'
