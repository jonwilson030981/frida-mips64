# frida-mips64

This repo is again based on ctng-mips64. It builds frida-gum for the MIPS64 architecture.

Our port is based on frida head. Our modifications are stored in a separate git repo in the features/mips64 branch. We modify various build scripts first of all to add support for MIPS64 to the SDK and various source files in frida-gum.

You can use 'make shell' to start a shell in a built container, or 'make run' to launch straight into running unit tests on a target QEMU image

# ctng-mips64
This is the toolchain used to build my MIPS64 binaries derived from crosstool-ng
https://github.com/jonwilson030981/ctng-mips64

# target-mips64
This is the target used for initial testing (prior to the actual embedded system), it is a MIPS64 linux environment running inside QEMU in a docker container.
https://github.com/jonwilson030981/target-mips64
