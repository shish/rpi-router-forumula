#!/bin/bash

iptables -t mangle -F

#######################################################################
# Routed from clients

iptables -t mangle -X marking || true
iptables -t mangle -N marking
iptables -t mangle -A PREROUTING -j marking
iptables -t mangle -A OUTPUT -j marking

iptables -t mangle -X three || true
iptables -t mangle -N three
iptables -t mangle -A three -j TOS --set-tos 0x08
iptables -t mangle -A three -j CONNMARK --set-mark 3
iptables -t mangle -A three -j ACCEPT

iptables -t mangle -X vodafone || true
iptables -t mangle -N vodafone
iptables -t mangle -A vodafone -j TOS --set-tos 0x04
iptables -t mangle -A vodafone -j CONNMARK --set-mark 4
iptables -t mangle -A vodafone -j ACCEPT

function cheap {
	local COMMENT=$1
	shift
	iptables -t mangle -A marking $* -j three -m comment --comment "$COMMENT Three"
}

function fast {
	local COMMENT=$1
	shift
	iptables -t mangle -A marking $* -j vodafone -m comment --comment "$COMMENT Vodafone"
}

# Three's network is totally unusable at peak times
# fast "HTTP(S) during busy hours" -p tcp -m multiport --dports 80,443 -m time --timestart 18:00:00 --timestop 23:00:00
# fast "QUIC during busy hours" -p udp -m multiport --dports 80,443 -m time --timestart 18:00:00 --timestop 23:00:00

# System stuff
cheap "Premarked Connection" -m connmark --mark 3
fast "Premarked Connection" -m connmark --mark 4
cheap "Premarked Packet" -m tos --tos 0x08/0x08
fast "Premarked Packet" -m tos --tos 0x04/0x04

# Specific destinations
cheap "Dongle" -p tcp -m tcp --dport 80 -d 192.168.8.1
fast "Graphs" -p tcp -m tcp --dport 443 -d aster.shishnet.org
fast "Tesco" -p tcp -m tcp --dport 443 -d tesco.ie

# Specific protocols
fast "DNS" -p udp -m udp --dport 53
fast "25% of InfluxDB" -p tcp -m tcp --dport 8086 -m statistic --mode random --probability 0.25
cheap "InfluxDB" -p tcp -m tcp --dport 8086
fast "Salt" -p tcp -m multiport --dports 4505,4506
cheap "QUIC" -p udp -m udp --dport 443
fast "Overwatch" -p tcp -m multiport --dports 1119,3724,6113
fast "Overwatch" -p udp -m multiport --dports 26500:26599

# Default
cheap "Default"

# Save for net boot
iptables-save > /etc/iptables/rules.v4
