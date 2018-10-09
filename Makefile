.PHONY: all run
PWD = $(shell pwd)
UID = $(shell id -u)
GID = $(shell id -g)
PORT = 3000
COMMANDS := " \
	cp  /home/build/frida/build/tmp-linux-mips64/frida-gum/tests/gum-tests /mnt/; \
	chown $(UID):$(GID) /mnt/gum-tests; \
	mips64-unknown-linux-gnu-strip /home/build/frida/build/tmp-linux-mips64/frida-gum/tests/gum-tests; \
	cp /home/build/frida/build/tmp-linux-mips64/frida-gum/tests/gum-tests /mnt/gum-tests-stripped; \
	chown $(UID):$(GID) /mnt/gum-tests-stripped; \
	cp /home/build/frida/test /mnt/test; \
	chown $(UID):$(GID) /mnt/test; \
	cp /home/build/frida/test /mnt/test-stripped; \
	mips64-unknown-linux-gnu-strip /mnt/test-stripped; \
	chown $(UID):$(GID) /mnt/test-stripped; \
	"

all:
	docker build -t frida-mips64 .
	mkdir -p bin
	docker run --rm --name frida-mips64 -v $(PWD)/bin/:/mnt frida-mips64 /bin/bash -c $(COMMANDS)

run: all
	docker run --rm -ti --name frida-mips64 frida-mips64 /bin/bash

debug: all
	docker run --rm -ti --name frida-mips64 -p $(PORT):$(PORT) --network=host frida-mips64 gdb-multiarch

push: all
	docker image tag frida-mips64 repo.treescale.com/jonwilson/private/frida-mips64
	docker push repo.treescale.com/jonwilson/private/frida-mips64
	docker rmi repo.treescale.com/jonwilson/private/frida-mips64

clean: rm rmi

rmi:
	docker image ls | grep none | cut -c 41-52 | xargs -r docker rmi --force

rm:
	docker ps -a | grep -v CONTAINER | cut -d " " -f 1 | xargs -r docker rm --force
