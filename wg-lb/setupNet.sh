#!/bin/bash
set -e
set -x

topology=${TOPOLOGY:?need to pass TOPOLOGY!}

main() {
  iface=$(getInterface)
  hostIp=$(getHostIp)

  # ip link add dev wg0 type wireguard

  #below should be done in root somehow?
  echo 1 > /proc/sys/net/ipv4/ip_forward

  applyTopology

  ip link set dev wg0 up

  ./lb.sh $iface $hostIp
}

getInterface() {
  ip link \
    | awk '$1 ~ /\d+:/ && /eth/ {print $2}' \
    | cut -d@ -f1 \
    | cut -d: -f1
}

getHostIp() {
  ip -o -4 addr list $iface \
  | awk '{print $4}' | cut -d/ -f1
}

applyTopology() {
  echo "$topology" | awk '
    /^listenPort/ {
      system("wg set wg0 listen-port "$2)
      next
    }
    /^ipPrefix/ { 
      ipPrefix=$2 
      system("ip addr add dev wg0 "ipPrefix".0/24")
      next
    }
    /^peer 0/ {
      system("bash -c \"wg set wg0 private-key <(echo "$4")\"")
      next
    }
    /^peer/ {
      system("wg set wg0 peer "$3)
      system("wg set wg0 peer "$3" allowed-ips "ipPrefix"."$2"/32")
    }
  '
}

main
