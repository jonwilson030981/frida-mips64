.PHONY: all run
PWD = $(shell pwd)
UID = $(shell id -u)
GID = $(shell id -g)
PORT = 3000
ARCHS := mips mips64

define build
$(strip $1):
	docker build \
		--build-arg arch=$(strip $1) \
		--build-arg build_arch=$(strip $1) \
		--build-arg target=linux-gnu \
		-t frida-$(strip $1) .

run-$(strip $1): $(strip $1)
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
