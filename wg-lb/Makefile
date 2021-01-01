SHELL:=/bin/bash

/out/wg-lb.id: $(shell find . -type f) /out/builder.id
	linuxkit pkg build -disable-content-trust .
	echo cirslis/wg-lb > $@

