FROM linuxkit/alpine:e2391e0b164c57db9f6c4ae110ee84f766edc430 AS mirror
RUN apk add curl
RUN apk add --no-cache --initdb \
    alpine-baselayout \
    busybox \
    iproute2 \
    iptables \
    ebtables \
    ipvsadm \
    bridge-utils \
    musl \
    wireguard-tools

RUN apk add --no-cache bash vim

