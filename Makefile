SHELL:=/bin/bash

name:=austina
version:=0.0.9

img:=out/$(name)-bios.img
vhd:=out/$(name)-$(version).vhd


$(vhd): $(img)
	qemu-img convert \
		-O vpc \
		-o subformat=fixed,force_size \
		$(img) $@

$(img): export TOPOLOGY=$(shell scripts/extractHubTopology)
$(img): export WGLB_ID=$(shell cat out/wg-lb.id)
$(img): $(shell find image) out/wg-lb.id out/topology.gpg
	cd image && \
		DEBUG=1 linuxkit build \
			-format raw-bios \
			-disable-content-trust \
			-dir ../out \
			-name $(name) \
			<(cat image.yml | envsubst)

out/wg-lb.id: $(shell find wg-lb)
	cd wg-lb && \
		linuxkit pkg build . \
		| awk '/^Successfully tagged/ {print $$3}' \
		> ../$@

out/:
	mkdir -p out


out/topology.gpg: scripts/genTopology vars/ipPrefix vars/proxyUrl vars/listenPort
	echo "will regenerate all keys etc - press return to continue..." && read _
	scripts/genTopology


deploy: deploy.tf
	terraform apply -var "tag=$(version)"

run: scripts/run
	scripts/run

clean:
	rm -rf out
