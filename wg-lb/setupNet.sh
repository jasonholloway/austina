#!/bin/sh

hostIp=$(ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)


ip link add dev wg0 type wireguard

ip addr add dev wg0 10.10.10.1/24

/usr/bin/wg setconf wg0 /etc/wireguard/wg0.conf

ip link set dev wg0 up

echo 1 > /proc/sys/net/ipv4/ip_forward

# the below should be set up on connection
# or even better, a haproxy config auto-generated

iptables \
  -t nat \
  -A PREROUTING \
  -i eth0 \
  -p tcp \
  -d "$hostIp" \
  ! --dport 22 \
  -j DNAT \
  --to-destination 10.10.10.2

iptables \
  -t nat \
  -A POSTROUTING \
  -p tcp \
  ! --dport 22 \
  -j MASQUERADE


# we want haproxy plus a repeated script that reads wg state
