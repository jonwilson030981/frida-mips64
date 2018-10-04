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
RUN git clone https://github.com/frida/frida.git -b 12.2.8
WORKDIR /home/build/frida
COPY src/config.site.in /home/build/frida/releng/
COPY src/setup-env.sh /home/build/frida/releng/
COPY src/Makefile.sdk.mk /home/build/frida/

RUN make -f Makefile.sdk.mk FRIDA_HOST=linux-mips64 build/fs-linux-mips64/lib/pkgconfig/liblzma.pc
RUN make -f Makefile.sdk.mk FRIDA_HOST=linux-mips64 build/fs-linux-mips64/lib/pkgconfig/sqlite3.pc
RUN make -f Makefile.sdk.mk FRIDA_HOST=linux-mips64 build/fs-linux-mips64/lib/pkgconfig/libunwind.pc
#RUN make -f Makefile.sdk.mk FRIDA_HOST=linux-mips64 build/fs-linux-mips64/lib/libiconv.a
RUN make -f Makefile.sdk.mk FRIDA_HOST=linux-mips64 build/fs-linux-mips64/lib/libelf.a
RUN make -f Makefile.sdk.mk FRIDA_HOST=linux-mips64 build/fs-linux-mips64/lib/libdwarf.a
RUN make -f Makefile.sdk.mk FRIDA_HOST=linux-mips64 build/fs-linux-mips64/lib/pkgconfig/libffi.pc
RUN make -f Makefile.sdk.mk FRIDA_HOST=linux-mips64 build/fs-linux-mips64/lib/pkgconfig/glib-2.0.pc
RUN make -f Makefile.sdk.mk FRIDA_HOST=linux-mips64 build/fs-linux-mips64/lib/pkgconfig/glib-openssl-static.pc
RUN make -f Makefile.sdk.mk FRIDA_HOST=linux-mips64 build/fs-linux-mips64/lib/pkgconfig/gee-0.8.pc
RUN make -f Makefile.sdk.mk FRIDA_HOST=linux-mips64 build/fs-linux-mips64/lib/pkgconfig/json-glib-1.0.pc
RUN make -f Makefile.sdk.mk FRIDA_HOST=linux-mips64 build/fs-linux-mips64/lib/pkgconfig/libsoup-2.4.pc
RUN make -f Makefile.sdk.mk FRIDA_HOST=linux-mips64 build/sdk-linux-mips64.tar.bz2

COPY src/Makefile.linux.mk /home/build/frida
RUN make build/.frida-gum-submodule-stamp

USER root
RUN apt-get install -y npm
USER build

RUN make build/.frida-gum-npm-stamp
#RUN make build/frida-linux-mips64/lib/pkgconfig/capstone.pc
#RUN make build/frida-linux-mips64/lib/pkgconfig/frida-gum-1.0.pc


USER root

