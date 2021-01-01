SHELL:=/bin/bash

version:=0.0.4
builder:=tmp$(shell uuidgen)

out/austina-$(version).vhd: $(shell find image -type f) out/builder.id out/wg-lb.id 
	docker run --rm \
		-v ${PWD}/image:/image:ro \
		-v ${PWD}/out:/out \
		-v /var/run/docker.sock:/var/run/docker.sock \
	  -w /image \
		$(file < out/builder.id) \
		make version=$(version)

out/wg-lb.id: $(shell find wg-lb -type f) out/builder.id
	docker run --rm \
		-v ${PWD}/wg-lb:/wg-lb:ro \
		-v ${PWD}/out:/out \
		-v /var/run/docker.sock:/var/run/docker.sock \
	  -w /wg-lb \
		$(file < out/builder.id) \
		make

out/builder.id: Dockerfile out/
	docker build -t $(builder) . 1>&2
	echo $(builder) > $@

out/:
	mkdir -p out


keys: keys/austina.pubkey keys/client.pubkey

keys/:
	mkdir -p keys

keys/austina.key.gpg keys/austina.pubkey: keys/
	wg genkey \
		| tee >(wg pubkey > keys/austina.pubkey) \
		| gpg -c -o keys/austina.key.gpg

keys/client.key.gpg keys/client.pubkey: keys/
	wg genkey \
		| tee >(wg pubkey > keys/client.pubkey) \
		| gpg -c -o keys/client.key.gpg


deploy: deploy.tf
	terraform apply -var "tag=$(version)"
