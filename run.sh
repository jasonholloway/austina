#!/bin/bash
set -x

cd out

linuxkit run qemu \
	-publish 2022:22/tcp \
	-publish 12375:52375/tcp \
	-publish 51820:51820/udp \
	austina-0.0.4.vhd
