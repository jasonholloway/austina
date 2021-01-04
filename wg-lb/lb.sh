#!/bin/bash

sshPort=${1:-22}
wgPort=${2:-49991}

main() {
  readEndpoints \
  | uniq \
  | setupRules
}

readEndpoints() {
  while sleep 0.5s; do
    wg | gawk '
      /allowed ips:/ { 
        match($3, /^(.+)\//, ip) 
      }
      /handshake:/ { 
        match($0, /([0-9]+) minutes/, min)
        if(min[1] < 3) print ip[1] 
      }
    ' | sort | xargs
  done
}

uniq() {
  stdbuf -oL -eL uniq
}

setupRules() {
  while read ips; do
    ./clean.sh

    iface=$(getInterface)
    hostIp=$(getHostIp $iface)
    udpPorts="$(getLocalUdpPorts)"
    tcpPorts="$(getLocalTcpPorts)"
      
    c=$(echo $ips | wc -w)
    i=0
    for ip in $ips; do 
      forward $ip $i $c
      let i+=1
    done

    masquerade
  done
}

forward() {
  ip=$1
  i=$2
  c=$3

  echo "$hostIp->$ip ($i/$c)"

  iptables \
    -t nat \
    -A PREROUTING \
    -i $iface \
    -d $hostIp \
    -p tcp \
    -m tcp \
      $(excludePorts "$tcpPorts") \
    -m state \
      --state NEW \
    -m statistic \
      --mode nth --every $((c-i)) --packet 0 \
    -m comment \
      --comment ZZZ \
    -j DNAT \
      --to-destination $ip

  iptables \
    -t nat \
    -A PREROUTING \
    -i $iface \
    -d $hostIp \
    -p udp \
    -m udp \
      $(excludePorts "$udpPorts") \
    -m state \
      --state NEW \
    -m statistic \
      --mode nth --every $((c-i)) --packet 0 \
    -m comment \
      --comment ZZZ \
    -j DNAT \
      --to-destination $ip
}

masquerade() {
  iptables \
    -t nat \
    -A POSTROUTING \
    -j MASQUERADE \
    -m comment --comment ZZZ
}

getInterface() {
  ip link \
    | gawk '$1 ~ /^[0-9]+:/ && /eth/ {print $2}' \
    | cut -d@ -f1 \
    | cut -d: -f1
}

getHostIp() {
  ip -o -4 addr list $iface \
  | awk '{print $4}' | cut -d/ -f1
}

getLocalUdpPorts() {
  netstat -au \
  | gawk '/^udp/ {match($4, /:([0-9]+)$/, p); print p[1]}' \
  | sort \
  | uniq
}

getLocalTcpPorts() {
  netstat -at \
  | gawk '/^tcp/ {match($4, /:([0-9]+)$/, p); print p[1]}' \
  | sort \
  | uniq
}

excludePorts() {
  ports="$1" 
  echo "$ports" | xargs -r echo "! --dport"
}


main $@
