FROM hairyhenderson/gomplate:v3.2.0-slim AS gomplate
FROM ubuntu:16.04 as build

RUN apt-get update &&\
    apt-get install -y sudo time git-core subversion build-essential gcc-multilib \
                       libncurses5-dev zlib1g-dev gawk flex gettext wget unzip \
                       curl python3 &&\
    apt-get clean

COPY --from=gomplate /gomplate /bin/gomplate

RUN useradd -m openwrt &&\
    echo 'openwrt ALL=NOPASSWD: ALL' > /etc/sudoers.d/openwrt

USER openwrt
WORKDIR /home/openwrt
