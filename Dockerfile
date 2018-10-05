FROM ctng-mips64

USER root
RUN apt-get update
RUN apt-get install -y git

USER build

# BUILD ZLIB
WORKDIR /home/build
RUN wget https://zlib.net/zlib-1.2.11.tar.gz
RUN tar zxvf zlib-1.2.11.tar.gz
WORKDIR /home/build/zlib-1.2.11/
RUN CC="mips64-unknown-linux-gnu-gcc -march=mips64r2" ./configure
RUN CC="mips64-unknown-linux-gnu-gcc -march=mips64r2" make

# INSTALL FRIDA BUILD DEPENDENCIES
USER root
RUN apt-get install -y python python3 language-pack-en-base

# CLONE FRIDA
USER build
WORKDIR /home/build/
RUN git clone https://github.com/frida/frida.git
WORKDIR /home/build/frida
RUN git checkout -b 12.2.8

# Patch the build scripts for mips64
COPY src/config.site.in /home/build/frida/releng/
COPY src/setup-env.sh /home/build/frida/releng/
COPY src/Makefile.sdk.mk /home/build/frida/

# Build the SDK
RUN make -f Makefile.sdk.mk FRIDA_HOST=linux-mips64 build/fs-linux-mips64/lib/pkgconfig/liblzma.pc
RUN make -f Makefile.sdk.mk FRIDA_HOST=linux-mips64 build/fs-linux-mips64/lib/pkgconfig/sqlite3.pc
RUN make -f Makefile.sdk.mk FRIDA_HOST=linux-mips64 build/fs-linux-mips64/lib/pkgconfig/libunwind.pc
RUN make -f Makefile.sdk.mk FRIDA_HOST=linux-mips64 build/fs-linux-mips64/lib/libelf.a
RUN make -f Makefile.sdk.mk FRIDA_HOST=linux-mips64 build/fs-linux-mips64/lib/libdwarf.a
RUN make -f Makefile.sdk.mk FRIDA_HOST=linux-mips64 build/fs-linux-mips64/lib/pkgconfig/libffi.pc
RUN make -f Makefile.sdk.mk FRIDA_HOST=linux-mips64 build/fs-linux-mips64/lib/pkgconfig/glib-2.0.pc
RUN make -f Makefile.sdk.mk FRIDA_HOST=linux-mips64 build/fs-linux-mips64/lib/pkgconfig/glib-openssl-static.pc
RUN make -f Makefile.sdk.mk FRIDA_HOST=linux-mips64 build/fs-linux-mips64/lib/pkgconfig/gee-0.8.pc
RUN make -f Makefile.sdk.mk FRIDA_HOST=linux-mips64 build/fs-linux-mips64/lib/pkgconfig/json-glib-1.0.pc
RUN make -f Makefile.sdk.mk FRIDA_HOST=linux-mips64 build/fs-linux-mips64/lib/pkgconfig/libsoup-2.4.pc
RUN make -f Makefile.sdk.mk FRIDA_HOST=linux-mips64 build/sdk-linux-mips64.tar.bz2

# Install pre-requisites for gum
USER root
RUN apt-get install -y nodejs-legacy npm
RUN wget https://deb.nodesource.com/setup_8.x
RUN chmod +x setup_8.x
RUN ./setup_8.x
RUN apt-get install -y nodejs
USER build

# Build frida-gum
RUN make build/frida-env-linux-x86_64.rc
COPY src/Makefile.linux.mk /home/build/frida
RUN make FRIDA_HOST=linux-mips64 build/.frida-gum-submodule-stamp
RUN make FRIDA_HOST=linux-mips64 NODE_BIN_DIR=/usr/bin build/.frida-gum-npm-stamp
RUN make build/frida-linux-mips64/lib/pkgconfig/capstone.pc
RUN make build/frida-linux-mips64/lib/pkgconfig/frida-gum-1.0.pc

USER root

