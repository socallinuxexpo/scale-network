#!/usr/bin/env bash

#####
#
# Compile all the ways to grab artifacts for openwrt imgs
# with the goal of setting update factory.img for flashing
#
#####

if [ -n "${WORMHOLE_CODE}" ]; then
  # Assumes runner has magic-wormhole installed
  wormhole receive --accept-file ${WORMHOLE_CODE} -o factory.img
else
  echo "TODO: other things with artifacts"
  #curl https://gitlab.com/socallinuxexpo/scale-network/-/jobs/artifacts/${BRANCH}/download?job=${OPENWRT_BUILD_JOB}
fi
