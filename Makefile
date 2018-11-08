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
	-redir tcp:$(PORT)::$(PORT) \

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

define build
$(strip $1):
	docker build \
		--build-arg arch=$(strip $1) \
		--build-arg build_arch=$(strip $1) \
		-t frida-$(strip $1) .

run-$(strip $1): $(strip $1)
ifeq ($(strip $(shell echo '$(strip $1)' | head -c6)),mips64)
	docker run --rm -ti \
		--name frida-$(strip $1) \
		-p $(PORT):$(PORT) \
		frida-$(strip $1) \
		/bin/bash -c "$(QEMU64)"
else
	docker run --rm -ti \
		--name frida-$(strip $1) \
		-p $(PORT):$(PORT) \
		frida-$(strip $1) \
		/bin/bash -c "$(QEMU)"
endif

shell-$(strip $1): $(strip $1)
	docker run --rm -ti \
		--name frida-$(strip $1) \
		frida-$(strip $1) \
		/bin/bash

push-$(strip $1): $(strip $1)
	docker tag frida-$(strip $1) jonwilson030981/frida-$(strip $1)
	docker push jonwilson030981/frida-$(strip $1)

endef

$(foreach a, $(ARCHS), $(eval $(call build, $a)))

clean: rm rmi

rmi:
	docker image ls | grep none | cut -c 41-52 | xargs -r docker rmi --force

rm:
	docker ps -a | grep -v CONTAINER | cut -d " " -f 1 | xargs -r docker rm --force
