FROM hairyhenderson/gomplate:v3.2.0-slim AS gomplate
FROM ubuntu:24.04 AS build


ENV TZ=ETC/UTC
ENV DEBIAN_FRONTEND=noninteractive


RUN apt-get update &&\
    apt-get install -y sudo time git-core subversion build-essential gcc-multilib \
                       libncurses5-dev \
                       zlib1g-dev gawk flex gettext wget unzip \
                       curl rsync python3 file swig zstd \
                       python3-setuptools python3-dev pkg-config &&\
    apt-get clean

COPY --from=gomplate /gomplate /bin/gomplate

USER ubuntu
WORKDIR /home/ubuntu
