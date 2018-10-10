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

RUN cp releng/devkit-assets/frida-gum-example-unix.c test.c
RUN sed -i "s/frida-gum.h/gum.h/g" test.c
RUN mips64-unknown-linux-gnu-gcc -o test test.c \
	-Wno-pointer-to-int-cast \
	-I ./build/frida-linux-mips64/include/frida-1.0/gum/ \
	-I ./build/frida-linux-mips64/include/frida-1.0/ \
	-I ./build/fs-linux-mips64/include/glib-2.0 \
	-I ./build/fs-linux-mips64/lib/glib-2.0/include/ \
	-I ./build/frida-linux-mips64/include/ \
	-ldl \
	-l rt \
	-l resolv \
	-l m \
	-lpthread \
	./build/frida-linux-mips64/lib/libfrida-gum-1.0.a \
	./build/sdk-linux-mips64/lib/libgobject-2.0.a \
	./build/sdk-linux-mips64/lib/libelf.a \
	./build/sdk-linux-mips64/lib/liblzma.a \
	./build/sdk-linux-mips64/lib/libz.a  \
	./build/sdk-linux-mips64/lib/libffi.a \
	./build/frida-linux-mips64/lib/libcapstone.a \
	./build/sdk-linux-mips64/lib/libgio-2.0.a \
	./build/fs-linux-mips64/lib/libgmodule-2.0.a \
	./build/sdk-linux-mips64/lib/gio/modules/libgioopenssl-static.a \
	./build/sdk-linux-mips64/lib/libglib-2.0.a \
	./build/sdk-linux-mips64/lib/libgobject-2.0.a

USER root
RUN apt-get install -y gdb vim cmake python3-pip gdb-multiarch
RUN wget -O ~/.gdbinit-gef.py -q https://github.com/hugsy/gef/raw/master/gef.py
RUN pip3 install --upgrade pip
RUN pip3 install unicorn keystone-engine keystone-engine ropper
RUN ln -s /usr/local/lib/python3.5/dist-packages/usr/lib/python3/dist-packages/keystone/libkeystone.so /usr/local/lib/python3.5/dist-packages/keystone/libkeystone.so
ENV LC_CTYPE C.UTF-8

USER build

# Patch for elf-module addresses
COPY src/gumelfmodule.c /home/build/frida/frida-gum/gum/backend-elf/gumelfmodule.c
COPY src/gummipsrelocator.c /home/build/frida/frida-gum/gum/arch-mips/gummipsrelocator.c
RUN make -C /home/build/frida/ build/frida-linux-mips64/lib/pkgconfig/frida-gum-1.0.pc

USER root
RUN apt-get install -y gdb vim cmake python3-pip gdb-multiarch
RUN wget -O ~/.gdbinit-gef.py -q https://github.com/hugsy/gef/raw/master/gef.py
RUN pip3 install --upgrade pip
RUN pip3 install unicorn keystone-engine keystone-engine ropper

COPY src/test.c /home/build/frida/
RUN mips64-unknown-linux-gnu-gcc -o test test.c \
	-Wno-pointer-to-int-cast \
	-I ./build/frida-linux-mips64/include/frida-1.0/gum/ \
	-I ./build/frida-linux-mips64/include/frida-1.0/ \
	-I ./build/fs-linux-mips64/include/glib-2.0 \
	-I ./build/fs-linux-mips64/lib/glib-2.0/include/ \
	-I ./build/frida-linux-mips64/include/ \
	-ldl \
	-l rt \
	-l resolv \
	-l m \
	-lpthread \
	./build/frida-linux-mips64/lib/libfrida-gum-1.0.a \
	./build/sdk-linux-mips64/lib/libgobject-2.0.a \
	./build/sdk-linux-mips64/lib/libelf.a \
	./build/sdk-linux-mips64/lib/liblzma.a \
	./build/sdk-linux-mips64/lib/libz.a  \
	./build/sdk-linux-mips64/lib/libffi.a \
	./build/frida-linux-mips64/lib/libcapstone.a \
	./build/sdk-linux-mips64/lib/libgio-2.0.a \
	./build/fs-linux-mips64/lib/libgmodule-2.0.a \
	./build/sdk-linux-mips64/lib/gio/modules/libgioopenssl-static.a \
	./build/sdk-linux-mips64/lib/libglib-2.0.a \
	./build/sdk-linux-mips64/lib/libgobject-2.0.a

USER root
ENV SYSROOT /home/build/x-tools/mips64-unknown-linux-gnu/mips64-unknown-linux-gnu/sysroot
RUN mkdir -p $SYSROOT/root/
RUN cp /home/build/frida/build/tmp-linux-mips64/frida-gum/tests/gum-tests $SYSROOT/root/
RUN cp /home/build/frida/test $SYSROOT/root/
RUN mkdir -p $SYSROOT/root/data/

RUN echo "source ~/.gdbinit-gef.py" >> ~/.gdbinit
RUN echo "set sysroot $SYSROOT" >> ~/.gdbinit
RUN echo "target extended-remote localhost:3000" >> ~/.gdbinit
RUN echo "remote put $SYSROOT/root/gum-tests /root/gum-tests"  >> ~/.gdbinit
RUN echo "remote put $SYSROOT/root/test /root/test"  >> ~/.gdbinit
RUN echo "set remote exec-file /root/test"  >> ~/.gdbinit
