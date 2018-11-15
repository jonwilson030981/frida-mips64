ARG arch
FROM ctng-$arch as build

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
RUN git config --global url.https://github.com/.insteadOf git://github.com/

RUN git submodule update
RUN git submodule update --remote frida-gum

ARG build_arch

# Build the SDK
RUN make -f Makefile.sdk.mk FRIDA_LIBC=gnu FRIDA_HOST=linux-$build_arch

#
# TODO REMOVE THE NEXT BLOCK. WE DEPLOY THE SDKS SO WE CAN JUST CONTINUE 
# THE BUILD FROM THE GIT UPDATE WITHOUT HAVING TO BUILD THEM EACH TIME WE MAKE A CHANGE
#
RUN make build/frida-env-linux-x86_64.rc
RUN make build/frida-env-linux-$build_arch.rc FRIDA_LIBC=gnu FRIDA_HOST=linux-$build_arch
RUN git config --global url.https://github.com/jonwilson030981/libffi.git.insteadOf https://github.com/frida/libffi.git
RUN echo "test"
RUN make -B -f Makefile.sdk.mk FRIDA_LIBC=gnu FRIDA_HOST=linux-mips64 build/fs-linux-mips64/lib/pkgconfig/libffi.pc
RUN cp /home/build/frida/build/fs-tmp-linux-mips64/libffi/src/libffi.a /home/build/frida/build/fs-tmp-linux-mips64/package/lib/libffi.a
RUN cp /home/build/frida/build/fs-tmp-linux-mips64/libffi/src/libffi.a /home/build/frida/build/sdk-linux-mips64/lib/libffi.a
RUN git submodule update --remote frida-gum
RUN cd frida-gum && git log -n 1

# Build frida-gum
RUN make build/frida-linux-$build_arch/lib/pkgconfig/frida-gum-1.0.pc FRIDA_LIBC=gnu FRIDA_HOST=linux-$build_arch
RUN . ./build/fs-meson-env-linux-$build_arch.rc && cd ./frida-gum/tests/core/ && ./build-targetfunctions.sh linux $build_arch

FROM target-$arch as run
USER build
WORKDIR /home/build/
RUN mkdir -p frida/data/
WORKDIR /home/build/frida
ARG build_arch
COPY --from=build /home/build/frida/build/tmp-linux-$build_arch/frida-gum/tests/gum-tests .
COPY --from=build /home/build/frida/frida-gum/tests/data/specialfunctions-linux-$build_arch.so ./data/
COPY --from=build /home/build/frida/frida-gum/tests/data/targetfunctions-linux-$build_arch.so ./data/
RUN e2mkdir -O0 -G0 -P755 /home/build/buildroot-2016.02/output/images/rootfs.ext2:/root/data
RUN e2cp -O0 -G0 -P755 gum-tests /home/build/buildroot-2016.02/output/images/rootfs.ext2:/root
RUN e2cp -O0 -G0 -P755 data/specialfunctions-linux-$build_arch.so /home/build/buildroot-2016.02/output/images/rootfs.ext2:/root/data
RUN e2cp -O0 -G0 -P755 data/targetfunctions-linux-$build_arch.so /home/build/buildroot-2016.02/output/images/rootfs.ext2:/root/data
RUN echo "/root/gum-tests \
	-s /GumJS/Script/invalid_read_write_execute_results_in_exception#DUK \
	-s /GumJS/Script/script_can_be_compiled_to_bytecode#DUK \
	-s /GumJS/Script/source_maps_should_be_supported_for_our_runtime#DUK \
	" >> S99gum-tests
RUN e2cp -O0 -G0 -P755 S99gum-tests /home/build/buildroot-2016.02/output/images/rootfs.ext2:/etc/init.d