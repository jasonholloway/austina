FROM linuxkit/alpine:e2391e0b164c57db9f6c4ae110ee84f766edc430 AS mirror
RUN mkdir -p /out/etc/apk && cp -r /etc/apk/* /out/etc/apk/
RUN apk add curl
RUN apk add --no-cache --initdb -p /out \
  alpine-baselayout \
  busybox \
  iproute2 \
  iptables \
  ebtables \
  ipvsadm \
  bridge-utils \
  musl \
  wireguard-tools \
  bash \
  coreutils

RUN apk add --repository http://dl-cdn.alpinelinux.org/alpine/edge/main -p /out gawk

RUN apk add --no-cache -p /out tcpdump

RUN rm -rf /out/etc/apk /out/lib/apk /out/var/cache

FROM scratch
WORKDIR /
COPY --from=mirror /out/ /
COPY *.sh ./

ENTRYPOINT []
CMD []
