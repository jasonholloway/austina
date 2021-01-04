SHELL:=/bin/bash

name:=austina
version:=0.0.11

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
		linuxkit build \
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
	mkdir -p out
	echo "will regenerate all keys etc - press return to continue..." && read _
	scripts/genTopology


deploy: deploy.tf
	terraform apply -var "tag=$(version)"

runQemu: scripts/run
	scripts/run

runDocker: out/wg-lb.id out/topology.gpg
	docker run -it --rm --privileged \
		-e TOPOLOGY="$$(cat out/topology.gpg | gpg -d | base64 -w0)" \
		$$(<out/wg-lb.id) bash

clean:
	rm -rf out
