#!/bin/sh

main() {
	cleanForwarding
	cleanMasquerade
}

cleanForwarding() {
	iptables -t nat -L PREROUTING --line-numbers \
	| awk '/ZZZ/ { print $1 }' \
	| sort -rg \
	| while read i; do iptables -t nat -D PREROUTING $i; done
}

cleanMasquerade() {
	iptables -t nat -L POSTROUTING --line-numbers \
	| awk '/ZZZ/ { print $1 }' \
	| sort -rg \
	| while read i; do iptables -t nat -D POSTROUTING $i; done
}

main

