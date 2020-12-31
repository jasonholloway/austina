#!/bin/bash
set -x

cd out

linuxkit run qemu \
	-publish 12375:52375/tcp \
	-publish 51820:51820/udp \
	racetrack-proxy
