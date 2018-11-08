ARG arch
FROM ctng-$arch

USER root
RUN apt-get update

# INSTALL FRIDA BUILD DEPENDENCIES
RUN apt-get install -y \
    git \
    build-essential \
    gcc-multilib \
    libstdc++-5-dev \
    python-dev \
    python3-dev \
    language-pack-en-base \
    curl

RUN curl -sL https://deb.nodesource.com/setup_10.x | bash
RUN apt-get install -y nodejs

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

# Build frida-gum
RUN make build/frida-linux-$build_arch/lib/pkgconfig/frida-gum-1.0.pc FRIDA_LIBC=gnu FRIDA_HOST=linux-$build_arch
