##################################################################################################################################

ARG arch
FROM ubuntu:xenial as ctng
ARG arch

RUN apt-get update
RUN apt-get install -y \
    bzip2 \
    build-essential \
    gperf \
    bison \
    flex \
    texinfo \
    wget \
    help2man \
    gawk \
    libtool-bin \
    automake \
    ncurses-dev \
    python-dev

RUN useradd -ms /bin/bash build
USER build

WORKDIR /home/build/
RUN wget http://crosstool-ng.org/download/crosstool-ng/crosstool-ng-1.22.0.tar.bz2

RUN tar jxvf crosstool-ng-1.22.0.tar.bz2
WORKDIR crosstool-ng

RUN ./configure --enable-local
RUN make

COPY src/$arch/crosstool.config /home/build/crosstool-ng/.config
RUN sed -i "s/\${make}/make/g" scripts/build/libc/glibc.sh

# Disable HSTS because proxies
RUN sed -i "s/wget --passive-ftp --tries=3 -nc/wget --no-hsts --passive-ftp --tries=1 -nc/g" scripts/functions

RUN ./ct-ng build

ARG target
ARG vendor=unknown
ENV PATH $PATH:/home/build/x-tools/$arch-$vendor-linux-gnu/bin/

USER root


##################################################################################################################################

ARG arch
FROM ctng-$arch as target

ARG arch

RUN apt-get update
RUN apt-get install -y bc

USER build
WORKDIR /home/build/
RUN wget https://mirrors.edge.kernel.org/pub/linux/kernel/v4.x/linux-4.7.tar.gz
RUN tar zxvf linux-4.7.tar.gz
WORKDIR /home/build/linux-4.7

ENV ARCH mips
ARG target
ENV CROSS_COMPILE $arch-unknown-linux-gnu-
RUN echo $CROSS_COMPILE

COPY src/$arch/linux.config /home/build/linux-4.7/.config

RUN make vmlinux

USER root
RUN apt-get install -y qemu

USER build
WORKDIR /home/build/
RUN wget https://buildroot.org/downloads/buildroot-2016.02.tar.gz
RUN tar zxvf buildroot-2016.02.tar.gz

USER root
RUN apt-get install -y cpio unzip rsync

USER build
WORKDIR /home/build/buildroot-2016.02/
COPY src/$arch/buildroot.config /home/build/buildroot-2016.02/.config
RUN make

USER root
RUN apt-get install -y e2tools

USER build
WORKDIR /home/build/
RUN echo "gdbserver --multi 0.0.0.0:3000 &" >> S99gdb.sh

RUN resize2fs /home/build/buildroot-2016.02/output/images/rootfs.ext2 100M
RUN e2cp -O0 -G0 -P755 S99gdb.sh /home/build/buildroot-2016.02/output/images/rootfs.ext2:/etc/init.d/