SHELL:=/bin/bash

img:=/out/image-bios.img
vhd:=/out/austina-$(version).vhd

$(vhd): $(img)
	qemu-img convert \
		-O vpc \
		-o subformat=fixed,force_size \
		/out/image-bios.img $@

$(img): image.yml /out/wg-lb.id /out/builder.id
	linuxkit build \
		-format raw-bios \
		-disable-content-trust \
		-dir /out \
		image.yml
