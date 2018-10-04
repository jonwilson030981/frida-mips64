.PHONY: all run

all:
	docker build -t frida-mips64 .

run: all
	docker run --rm -ti --name frida-mips64 frida-mips64 /bin/bash

push: all
	docker image tag frida-mips64 repo.treescale.com/jonwilson/private/frida-mips64
	docker push repo.treescale.com/jonwilson/private/frida-mips64
	docker rmi repo.treescale.com/jonwilson/private/frida-mips64

clean: rm rmi

rmi:
	docker image ls | grep none | cut -c 41-52 | xargs -r docker rmi --force

rm:
	docker ps -a | grep -v CONTAINER | cut -d " " -f 1 | xargs -r docker rm --force