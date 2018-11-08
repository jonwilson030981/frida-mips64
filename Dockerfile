ARG arch
FROM ctng-$arch

USER root
RUN apt-get update

# INSTALL FRIDA BUILD DEPENDENCIES
RUN apt-get install -y git python python3 language-pack-en-base

# CLONE FRIDA
USER build
WORKDIR /home/build/
RUN git clone https://github.com/jonwilson030981/frida.git
WORKDIR /home/build/frida
RUN git checkout features/mips64
RUN git log -n1
RUN git submodule init
RUN git submodule update
RUN git submodule update --remote frida-gum

ARG build_arch

# Build the SDK
RUN make -f Makefile.sdk.mk FRIDA_LIBC=gnu FRIDA_HOST=linux-$build_arch
RUN make -f Makefile.sdk.mk


# Install pre-requisites for gum
USER root
RUN apt-get install -y nodejs-legacy npm
RUN wget https://deb.nodesource.com/setup_8.x
RUN chmod +x setup_8.x
RUN ./setup_8.x
RUN apt-get install -y nodejs

# Build frida-gum
USER build

RUN make FRIDA_HOST=linux-$build_arch build/.frida-gum-submodule-stamp
RUN make FRIDA_HOST=linux-$build_arch NODE_BIN_DIR=/usr/bin build/.frida-gum-npm-stamp
#RUN make build/frida-linux-$build_arch/lib/pkgconfig/capstone.pc
#RUN make build/frida-linux-$build_arch/lib/pkgconfig/frida-gum-1.0.pc
