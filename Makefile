SHELL:=/bin/bash

name=austina
version:=0.0.4

img:=out/$(name)-bios.img
vhd:=out/$(name)-$(version).vhd


$(vhd): $(img) out/
	qemu-img convert \
		-O vpc \
		-o subformat=fixed,force_size \
		$(img) $@

$(img): export TOPOLOGY=$(shell scripts/extractHubTopology)
$(img): $(shell find image) out/wg-lb.id out/topology.gpg
	cd image && \
		linuxkit build \
			-format raw-bios \
			-disable-content-trust \
			-dir ../out \
			-name $(name) \
			<(cat image.yml | envsubst)

out/wg-lb.id: $(shell find wg-lb) out/
	cd wg-lb; \
		linuxkit pkg build -disable-content-trust .
	echo cirslis/wg-lb > $@

out/:
	mkdir -p out


out/topology.gpg: scripts/genTopology out/ vars/ipPrefix vars/proxyUrl vars/listenPort
	echo "will regenerate all keys etc - press return to continue..." && read _
	scripts/genTopology


deploy: deploy.tf
	terraform apply -var "tag=$(version)"

run: scripts/run
	scripts/run

clean:
	rm -rf out
