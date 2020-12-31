#!/bin/sh
set -e

main() {
  prepFile wg0.conf
  prepFile haproxy.cfg
  buildVhd
  pipeOut
}

prepFile() {
  file="$1"
  data=$(cat "$file")
  echo "$data" | envsubst "$data" > "$file"
}

buildVhd() {
  linuxkit build \
    -format raw-bios \
    -disable-content-trust \
    image.yml \
    1>&2

  qemu-img convert \
    -O vpc \
    -o subformat=fixed,force_size \
    image-bios.img \
    image.vhd \
    1>&2
}

pipeOut() {
  cat image.vhd
}

main
