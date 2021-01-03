#!/bin/bash
set -e

topology=${TOPOLOGY:?need to pass TOPOLOGY!}

main() {
  ip link add dev wg0 type wireguard
  applyTopology
  ip link set dev wg0 up

  echo 1 > /proc/sys/net/ipv4/ip_forward
}

applyTopology() {
  echo "$topology" \
  | base64 -d \
  | awk '
    /^listenPort/ {
      system("wg set wg0 listen-port "$2)
      next
    }
    /^ipPrefix/ { 
      ipPrefix=$2 
      system("ip addr add dev wg0 "ipPrefix".1/24")
      next
    }
    /^peer 1/ {
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
