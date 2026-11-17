#!/usr/bin/env bash

OPENWRT_GIT="https://github.com/openwrt/openwrt"
OPENWRT_PKG_GIT="https://git.openwrt.org/feed/packages.git"

rm -rf .openwrt .packages
git clone --depth 1 ${OPENWRT_GIT} .openwrt
git clone --depth 1 ${OPENWRT_PKG_GIT} .packages

EXISTING_OPENWRT=$(cat Makefile | grep ^OPENWRT_VER | awk '{ print $3 }')
NEW_OPENWRT=$(cd .openwrt && git rev-parse HEAD && cd ..)

EXISTING_OPENWRT_PKG=$(cat Makefile | grep ^OPENWRT_PKG_VER | awk '{ print $3 }')
NEW_OPENWRT_PKG=$(cd .packages && git rev-parse HEAD && cd ..)

SEDCMD="$(which sed) -i"
if [ "$(uname)" == "Darwin" ]
then
    SEDCMD="${SEDCMD} .bak"
fi

if [ "${EXISTING_OPENWRT}" != "${NEW_OPENWRT}" ]
then
    echo "Outdated revision of ${OPENWRT_GIT}"
    echo "updating from ${EXISTING_OPENWRT} to ${NEW_OPENWRT}"
    ${SEDCMD} "s!${EXISTING_OPENWRT}!${NEW_OPENWRT}!" Makefile
fi

if [ "${EXISTING_OPENWRT_PKG}" != "${NEW_OPENWRT_PKG}" ]
then
    echo "Outdated revision of ${OPENWRT_PKG_GIT}"
    echo "updating from ${EXISTING_OPENWRT_PKG} to ${NEW_OPENWRT_PKG}"
    ${SEDCMD} "s!${EXISTING_OPENWRT_PKG}!${NEW_OPENWRT_PKG}!" Makefile
fi

rm -rf .openwrt .packages
if [ -f Makefile.bak ]
then
    rm Makefile.bak
fi

# Source patches: a bump of OPENWRT_VER or OPENWRT_PKG_VERSION can land a
# fix, make a patch stop applying, or fix the bug another way. See
# source-patches/README.md.
# Do not build one without-patch image per patch, and do not "make clean"
# a reusable built tree just to skip patches (that wipes the toolchain).
echo "After bumping OPENWRT_VER or OPENWRT_PKG_VERSION, run: make check-source-patches"
echo "A flagged check does not start a without-patch build. To confirm,"
echo "set SOURCE_PATCH_MODE=trial explicitly, with one image that has ALL"
echo "carried patches skipped (SKIP_SOURCE_PATCHES=001,002,packages/001,...)."
echo "Prefer a package-level rebuild on an existing tree; run each patch's"
echo "RUNTIME_TEST on a device (the deciding verdict). Bisect only if that"
echo "combined test FAILs. Feed patches also need 'make clean-feeds' if the"
echo "extract already exists."
