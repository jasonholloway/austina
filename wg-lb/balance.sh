#!/bin/bash

if=${1:-eth0}
hostIp=${2:-0.0.0.0}

main() {
  readEndpoints \
  | uniq \
  | setupRules
}

readEndpoints() {
  while sleep 0.5s; do
    wg | awk '
      /allowed ips:/ { 
        match($2, /^(.+)\//, ip) 
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
    -i $if \
    -p tcp \
    -d $hostIp \
    ! --dport 22 \
    -j DNAT \
    --to-destination $ip \
    -m state --state NEW \
    -m statistic --mode nth --every $c --packet $i \
    -m comment --comment ZZZ
}

masquerade() {
  iptables \
    -t nat \
    -A POSTROUTING \
    -p tcp \
    ! --dport 22 \
    -j MASQUERADE \
    -m comment --comment ZZZ
}

main $@
