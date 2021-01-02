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



clients:=$(foreach i,1 2 3 4,client$(i))
peers:=$(clients) austina

keys: $(foreach p,$(peers),keys/$(p).key.gpg keys/$(p).pubkey)

keys/:
	mkdir -p keys

keys/%.key.gpg keys/%.pubkey: keys/
	wg genkey \
		| tee >(wg pubkey > keys/$*.pubkey) \
		| gpg -c -o keys/$*.key.gpg


deploy: deploy.tf
	terraform apply -var "tag=$(version)"

clean:
	rm -rf out
