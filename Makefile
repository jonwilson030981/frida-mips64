PWD = $(shell pwd)
UID = $(shell id -u)
GID = $(shell id -g)
PORT = 3000
ARCHS := mips mips64 mips64el

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

define dist
dist-$(strip $1)-$(strip $2): $(strip $1)-$(strip $2)
	mkdir -p dist/$(strip $2)
	docker run --rm -ti \
		--name $(strip $1)-$(strip $2) \
		-v $(PWD)/dist/$(strip $2):/dist \
		$(strip $1)-$(strip $2) \
		/bin/cp /home/build/linux-4.7/vmlinux /dist

	docker run --rm -ti \
		--name $(strip $1)-$(strip $2) \
		-v $(PWD)/dist/$(strip $2):/dist \
		$(strip $1)-$(strip $2) \
		/bin/cp /home/build/buildroot-2016.02/output/images/rootfs.ext2 /dist

endef

# run a qemu image: 
#   $1 is the image name, 
#   $2 is the architecture, 
define qemu
launch-$(strip $1)-$(strip $2) : dist-$(strip $1)-$(strip $2)
	stty intr ^];
	qemu-system-mips \
		-m 256M \
		-nographic \
		-kernel $(PWD)/dist/$(strip $2)/vmlinux \
		--drive file=$(PWD)/dist/$(strip $2)/rootfs.ext2,format=raw \
		--drive file=/home/build/buildroot-2016.02/output/images/rootfs.ext2,format=raw \
		-append 'root=/dev/sda console=ttyS0 rw physmap.enabled=0 noapic' \
		-serial stdio \
		-monitor null \
		-redir tcp:$(PORT)::$(PORT)
endef

# run a qemu image: 
#   $1 is the image name, 
#   $2 is the architecture, 
define qemu64
launch-$(strip $1)-$(strip $2) : dist-$(strip $1)-$(strip $2)
	stty intr ^];
	qemu-system-mips64 \
		-cpu MIPS64R2-generic \
		-m 256M \
		-nographic \
		-kernel $(PWD)/dist/$(strip $2)/vmlinux \
		--drive file=$(PWD)/dist/$(strip $2)/rootfs.ext2,format=raw \
		-append 'root=/dev/sda console=ttyS0 rw physmap.enabled=0 noapic' \
		-serial stdio \
		-monitor null \
		-redir tcp:$(PORT)::$(PORT)
endef

# Build targets for a docker image: 
#   $1 is the architecture 
define docker

############################################################################

$(eval $(call build, ctng, $(strip $1)))
$(eval $(call run, ctng, $(strip $1)))

############################################################################

$(eval $(call build, target, $(strip $1), ctng-$(strip $1)))
$(eval $(call run, target, $(strip $1)))
$(eval $(call dist, target, $(strip $1)))
endef

$(foreach a, $(ARCHS), $(eval $(call docker, $a)))
$(eval $(call qemu, target, mips))
$(eval $(call qemu64, target, mips64))
$(eval $(call qemu64, target, mips64el))
