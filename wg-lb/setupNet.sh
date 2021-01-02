#!/bin/sh

iface=eth0
hostIp=$(ip -o -4 addr list $iface | awk '{print $4}' | cut -d/ -f1)

echo 1 > /proc/sys/net/ipv4/ip_forward

ip link add dev wg0 type wireguard
ip addr add dev wg0 ${cidr}

wg setconf wg0 wg0.conf

ip link set dev wg0 up

./balance.sh $iface $hostIp

