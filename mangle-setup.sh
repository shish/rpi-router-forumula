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
iptables -t mangle -A three -j MARK --set-mark 3
iptables -t mangle -A three -j CONNMARK --set-mark 3
iptables -t mangle -A three -j ACCEPT

iptables -t mangle -X vodafone || true
iptables -t mangle -N vodafone
iptables -t mangle -A vodafone -j MARK --set-mark 4
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

cheap "Premarked Connection" -m connmark --mark 3
fast "Premarked Connection" -m connmark --mark 4
cheap "Premarked Packet" -m mark --mark 3
fast "Premarked Packet" -m mark --mark 4

cheap "Dongle" -p tcp -d 192.168.8.1
fast "25% of InfluxDB" -p tcp -m tcp --dport 8086 -m statistic --mode random --probability 0.25
cheap "InfluxDB" -p tcp -m tcp --dport 8086
fast "Salt" -p tcp -m multiport --dports 4505,4506
cheap "QUIC" -p udp -m udp --dport 443
fast "DNS" -p udp -m udp --dport 53
fast "Overwatch" -p tcp -m multiport --dports 1119,3724,6113
fast "Overwatch" -p udp -m multiport --dports 26500:26599
cheap "Default"

# Save for net boot
iptables-save > /etc/iptables/rules.v4
