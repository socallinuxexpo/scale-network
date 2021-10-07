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
