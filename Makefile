SHELL:=/bin/bash

version:=0.0.4
builder:=tmp$(shell uuidgen)

img:=out/image-bios.img
vhd:=out/austina-$(version).vhd


$(vhd): $(img) out/
	qemu-img convert \
		-O vpc \
		-o subformat=fixed,force_size \
		out/image-bios.img $@

$(img): $(shell find image) out/wg-lb.id out/
	cd image; \
		linuxkit build \
			-format raw-bios \
			-disable-content-trust \
			-dir ../out \
			image.yml

out/wg-lb.id: $(shell find wg-lb) out/
	cd wg-lb; \
		linuxkit pkg build -disable-content-trust .
	echo cirslis/wg-lb > $@

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

clean:
	rm -rf out
