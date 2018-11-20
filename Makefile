.PHONY: all run
PWD = $(shell pwd)
UID = $(shell id -u)
GID = $(shell id -g)
PORT = 3000
ARCHS := mips mips64

QEMU := \
	stty intr ^]; \
	qemu-system-mips \
	-m 256M \
 	-nographic \
	-kernel /home/build/linux-4.7/vmlinux \
	--drive file=/home/build/buildroot-2016.02/output/images/rootfs.ext2,format=raw \
	-append 'root=/dev/sda console=ttyS0 rw physmap.enabled=0 noapic' \
	-serial stdio \
	-monitor null \
	-redir tcp:$(PORT)::$(PORT)


QEMU64 := \
	stty intr ^]; \
	qemu-system-mips64 \
	-m 256M \
 	-nographic \
	-kernel /home/build/linux-4.7/vmlinux \
	--drive file=/home/build/buildroot-2016.02/output/images/rootfs.ext2,format=raw \
	-append 'root=/dev/sda console=ttyS0 rw physmap.enabled=0 noapic' \
	-serial stdio \
	-monitor null \
	-redir tcp:$(PORT)::$(PORT) \
	-cpu MIPS64R2-generic

# Run a docker image. 
#   $1 is the image name, 
#   $2 is the architecture
define run 
run-$(strip $1)-$(strip $2): $(strip $1)-$(strip $2)
	docker run --rm -ti \
		--name $(strip $1)-$(strip $2) \
		$(strip $1)-$(strip $2) \
		/bin/bash
endef

# Build a docker image: 
#   $1 is the image name, 
#   $2 is the architecture, 
#   $3 is the dependent build stage (including architecture)
define build
$(strip $1)-$(strip $2): $(strip $3)
	docker build \
		--build-arg arch=$(strip $2) \
		--target $(strip $1) \
		-t $(strip $1)-$(strip $2) \
		.
endef

# Push a docker image: 
#   $1 is the image name, 
#   $2 is the architecture, 
define push
push-$(strip $1)-$(strip $2): $(strip $1)-$(strip $2)
	docker tag $(strip $1)-$(strip $2) jonwilson030981/$(strip $1)-$(strip $2)
	docker push jonwilson030981/$(strip $1)-$(strip $2)
endef

# Build targets for a docker image: 
#   $1 is the architecture 
define docker
$(eval $(call build, ctng, $(strip $1)))
$(info $(call build, ctng, $(strip $1)))

$(eval $(call run, ctng, $(strip $1)))
$(info $(call run, ctng, $(strip $1)))

$(eval $(call push, ctng, $(strip $1)))
$(info $(call push, ctng, $(strip $1)))

############################################################################

$(eval $(call build, target, $(strip $1), ctng-$(strip $1)))
$(info $(call build, target, $(strip $1), ctng-$(strip $1)))

$(eval $(call run, target, $(strip $1)))
$(info $(call run, target, $(strip $1)))

$(eval $(call push, target, $(strip $1)))
$(info $(call push, target, $(strip $1)))

############################################################################

$(eval $(call build, frida, $(strip $1), target-$(strip $1)))
$(info $(call build, frida, $(strip $1), target-$(strip $1)))

$(eval $(call run, frida, $(strip $1)))
$(info $(call run, frida, $(strip $1)))

$(eval $(call push, frida, $(strip $1)))
$(info $(call push, frida, $(strip $1)))

############################################################################

$(eval $(call build, test, $(strip $1), target-$(strip $1) frida-$(strip $1)))
$(info $(call build, test, $(strip $1), target-$(strip $1) frida-$(strip $1)))

$(eval $(call run, test, $(strip $1)))
$(info $(call run, test, $(strip $1)))

$(eval $(call push, test, $(strip $1)))
$(info $(call push, test, $(strip $1)))

endef

$(foreach a, $(ARCHS), $(eval $(call docker, $a)))

clean: rm rmi

rmi:
	docker image ls | grep none | cut -c 41-52 | xargs -r docker rmi --force

rm:
	docker ps -a | grep -v CONTAINER | cut -d " " -f 1 | xargs -r docker rm --force
