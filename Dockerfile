ARG arch
FROM ctng-$arch

USER root
RUN apt-get update
RUN apt-get install -y git

USER build

# BUILD ZLIB
WORKDIR /home/build
RUN wget https://zlib.net/zlib-1.2.11.tar.gz
RUN tar zxvf zlib-1.2.11.tar.gz
WORKDIR /home/build/zlib-1.2.11/
ARG build_arch
ARG target
ARG vendor=unknown
RUN CC="$build_arch-$vendor-$target-gcc" ./configure
RUN CC="$build_arch-$vendor-$target-gcc" make

# INSTALL FRIDA BUILD DEPENDENCIES
USER root
RUN apt-get install -y python python3 language-pack-en-base

# CLONE FRIDA
USER build
WORKDIR /home/build/
RUN echo test7
RUN git clone https://github.com/jonwilson030981/frida.git
WORKDIR /home/build/frida
RUN git checkout features/mips64
RUN git log -n1
RUN git submodule init
RUN git submodule update
RUN git submodule update --remote frida-gum

# Build the SDK
RUN make -f Makefile.sdk.mk FRIDA_LIBC=gnu FRIDA_CFLAGS=-I/home/build/zlib-1.2.11/ FRIDA_LDFLAGS=-L/home/build/zlib-1.2.11/ FRIDA_HOST=linux-$build_arch build/fs-linux-$build_arch/lib/pkgconfig/liblzma.pc
RUN make -f Makefile.sdk.mk FRIDA_LIBC=gnu FRIDA_CFLAGS=-I/home/build/zlib-1.2.11/ FRIDA_LDFLAGS=-L/home/build/zlib-1.2.11/ FRIDA_HOST=linux-$build_arch build/fs-linux-$build_arch/lib/pkgconfig/sqlite3.pc
RUN make -f Makefile.sdk.mk FRIDA_LIBC=gnu FRIDA_CFLAGS=-I/home/build/zlib-1.2.11/ FRIDA_LDFLAGS=-L/home/build/zlib-1.2.11/ FRIDA_HOST=linux-$build_arch build/fs-linux-$build_arch/lib/pkgconfig/libunwind.pc
RUN make -f Makefile.sdk.mk FRIDA_LIBC=gnu FRIDA_CFLAGS=-I/home/build/zlib-1.2.11/ FRIDA_LDFLAGS=-L/home/build/zlib-1.2.11/ FRIDA_HOST=linux-$build_arch build/fs-linux-$build_arch/lib/libelf.a
RUN make -f Makefile.sdk.mk FRIDA_LIBC=gnu FRIDA_CFLAGS=-I/home/build/zlib-1.2.11/ FRIDA_LDFLAGS=-L/home/build/zlib-1.2.11/ FRIDA_HOST=linux-$build_arch build/fs-linux-$build_arch/lib/libdwarf.a
RUN make -f Makefile.sdk.mk FRIDA_LIBC=gnu FRIDA_CFLAGS=-I/home/build/zlib-1.2.11/ FRIDA_LDFLAGS=-L/home/build/zlib-1.2.11/ FRIDA_HOST=linux-$build_arch build/fs-linux-$build_arch/lib/pkgconfig/libffi.pc
RUN make -f Makefile.sdk.mk FRIDA_LIBC=gnu FRIDA_CFLAGS=-I/home/build/zlib-1.2.11/ FRIDA_LDFLAGS=-L/home/build/zlib-1.2.11/ FRIDA_HOST=linux-$build_arch build/fs-linux-$build_arch/lib/pkgconfig/glib-2.0.pc
RUN make -f Makefile.sdk.mk FRIDA_LIBC=gnu FRIDA_CFLAGS=-I/home/build/zlib-1.2.11/ FRIDA_LDFLAGS=-L/home/build/zlib-1.2.11/ FRIDA_HOST=linux-$build_arch build/fs-linux-$build_arch/lib/pkgconfig/glib-openssl-static.pc
RUN make -f Makefile.sdk.mk FRIDA_LIBC=gnu FRIDA_CFLAGS=-I/home/build/zlib-1.2.11/ FRIDA_LDFLAGS=-L/home/build/zlib-1.2.11/ FRIDA_HOST=linux-$build_arch build/fs-linux-$build_arch/lib/pkgconfig/gee-0.8.pc
RUN make -f Makefile.sdk.mk FRIDA_LIBC=gnu FRIDA_CFLAGS=-I/home/build/zlib-1.2.11/ FRIDA_LDFLAGS=-L/home/build/zlib-1.2.11/ FRIDA_HOST=linux-$build_arch build/fs-linux-$build_arch/lib/pkgconfig/json-glib-1.0.pc
RUN make -f Makefile.sdk.mk FRIDA_LIBC=gnu FRIDA_CFLAGS=-I/home/build/zlib-1.2.11/ FRIDA_LDFLAGS=-L/home/build/zlib-1.2.11/ FRIDA_HOST=linux-$build_arch build/fs-linux-$build_arch/lib/pkgconfig/libsoup-2.4.pc
RUN make -f Makefile.sdk.mk FRIDA_LIBC=gnu FRIDA_CFLAGS=-I/home/build/zlib-1.2.11/ FRIDA_LDFLAGS=-L/home/build/zlib-1.2.11/ FRIDA_HOST=linux-$build_arch build/sdk-linux-$build_arch.tar.bz2