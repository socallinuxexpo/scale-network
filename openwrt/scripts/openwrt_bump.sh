#!/usr/bin/env bash

OPENWRT_GIT="https://github.com/openwrt/openwrt"
OPENWRT_PKG_GIT="https://git.openwrt.org/feed/packages.git"

for repo in ${OPENWRT_GIT} ${OPENWRT_PKG_GIT}
do
    git clone ${repo}
done

EXISTING_OPENWRT=$(cat Makefile | grep ^OPENWRT_VER | awk '{ print $3 }')
NEW_OPENWRT=$(cd openwrt && git rev-parse HEAD && cd ..)

EXISTING_OPENWRT_PKG=$(cat Makefile | grep ^OPENWRT_PKG_VER | awk '{ print $3 }')
NEW_OPENWRT_PKG=$(cd packages && git rev-parse HEAD && cd ..)

if [ "${EXISTING_OPENWRT}" != "${NEW_OPENWRT}" ]
then
    echo "Outdated revision of ${OPENWRT_GIT}"
    echo "updating from ${EXISTING_OPENWRT} to ${NEW_OPENWRT}"
    sed -i "s!${EXISTING_OPENWRT}!${NEW_OPENWRT}!" Makefile
    UPDATED=1
fi

if [ "${EXISTING_OPENWRT_PKG}" != "${NEW_OPENWRT_PKG}" ]
then
    echo "Outdated revision of ${OPENWRT_PKG_GIT}"
    echo "updating from ${EXISTING_OPENWRT_PKG} to ${NEW_OPENWRT_PKG}"
    sed -i "s!${EXISTING_OPENWRT_PKG}!${NEW_OPENWRT_PKG}!" Makefile
    UPDATED=1
fi

if [ -z "${UPDATED}" ]
then
    echo "Creating new branch"
    TIMESTAMP=$(date +%Y%m%d%H%M%s)
    git checkout -b "openwrt/${TIMESTAMP}"
    git push --set-upstream origin "openwrt/${TIMESTAMP}"
    # pull github creds from environment (circle context)
    # set sane git config (such as bot name, etc)
    # do pull request here with hub or something
fi
