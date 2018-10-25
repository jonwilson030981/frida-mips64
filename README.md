# frida-mips64

This repo is again based on ctng-mips64. It builds frida-gum for the MIPS64 architecture. We first download and build zlib as frida didn't pick up the one installed on the system for me.

Building frida on my computer takes a good while (I need to buy a new one) so the build is broken into several pieces, calling each target in the makefile in turn. In this way, should one of the steps fail, the docker file can be adjusted and the build carry on from the last successful step.

Our port is based on frida 12.2.8 since we want a fixed point on which to build. Various files which have been modified from the original are incorporated in the 'src/' directory. We replace various build scripts first of all to add support for MIPS64.

Docker then builds the SDK, installs pre-requisites for frida-gum (lots of javascript things) and then builds an unmodified version of frida-gum.

We then build frida-gum-example-unix.c (rebadged as test.c), but had to modify the header it was including. Suspect I did something wrong that the header wasn't picked up here, but a bit of sed works around it.

Now we install gdb-multiarch and gef to use as our debugger against the target. We setup a sysroot to contain all of the files we will push to the remote and copy in our .gdbinit.

Next we replace the source code of frida-gum with our modified files and rebuild it, we also build the target functions binary and re-build the frida-gum-example-unix.c.

We now populate our sysroot and add a utility script to run selected unit tests on the target.

You can use 'make run' to start a shell in a built container, or 'make debug' to launch straight into gdb. It seems that gdb fails with an assertion failure on alternte attempts to control the target. I'm not sure why, but retrying works around it.

# ctng-mips64
This is the toolchain used to build my MIPS64 binaries derived from crosstool-ng
https://github.com/jonwilson030981/ctng-mips64

# target-mips64
This is the target used for initial testing (prior to the actual embedded system), it is a MIPS64 linux environment running inside QEMU in a docker container.
https://github.com/jonwilson030981/target-mips64
