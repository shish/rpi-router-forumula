#!/bin/bash

ip route flush table 4
ip route show table main | grep -v default | grep -v wwanT | while read ROUTE ; do
    ip route add table 4 $ROUTE
done
ip route add table 4 default via 192.168.8.1 dev wwanV

ip route flush table 3
ip route show table main | grep -v default | grep -v wwanV | while read ROUTE ; do
    ip route add table 3 $ROUTE
done
ip route add table 3 default via 192.168.8.1 dev wwanT

ip rule | grep -q 'fwmark 0x3' || ip rule add fwmark 3 lookup 3
ip rule | grep -q 'fwmark 0x4' || ip rule add fwmark 4 lookup 4

iptables -t nat -F
iptables -t mangle -F

#######################################################################
# Squid intercept

iptables -t nat -A PREROUTING -s 192.168.8.100 -p tcp --dport 80 -j ACCEPT
iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination 192.168.5.1:3128
# iptables -t nat -A PREROUTING -p tcp --dport 443 -j DNAT --to-destination 192.168.5.1:3129
iptables -t mangle -A PREROUTING -p tcp --dport 3128 -j DROP

#######################################################################
# Output from us

iptables -t mangle -A OUTPUT -m mark --mark 3 -j ACCEPT -m comment --comment "Premarked Three"
iptables -t mangle -A OUTPUT -m mark --mark 4 -j ACCEPT -m comment --comment "Premarked Vodafone"
iptables -t mangle -A OUTPUT -p tcp -m tcp --dport 8086 -j MARK --set-mark 3 -m comment --comment "InfluxDB Three"
iptables -t mangle -A OUTPUT -p tcp -m multiport --dports 80,443 -j MARK --set-mark 3 -m comment --comment "HTTP(S) Three"
iptables -t mangle -A OUTPUT -p tcp -m tcp --dport 5201 -j MARK --set-mark 3 -m comment --comment "iperf3 Three"
iptables -t mangle -A OUTPUT -p tcp -m tcp --dport 5202 -j MARK --set-mark 4 -m comment --comment "iperf3 Vodafone"


#######################################################################
# Routed from clients

iptables -t nat -A POSTROUTING -j MASQUERADE

function cheap {
	local COMMENT=$1
	shift
	iptables -t mangle -A PREROUTING $* -j MARK --set-mark 3 -m comment --comment "$COMMENT Three"
	iptables -t mangle -A PREROUTING $* -j ACCEPT
}

function fast {
	local COMMENT=$1
	shift
	iptables -t mangle -A PREROUTING $* -j MARK --set-mark 4 -m comment --comment "$COMMENT Vodafone"
	iptables -t mangle -A PREROUTING $* -j ACCEPT
}

# Three's network is totally unusable at peak times
# fast "HTTP(S) during busy hours" -p tcp -m multiport --dports 80,443 -m time --timestart 18:00:00 --timestop 23:00:00
# fast "QUIC during busy hours" -p udp -m multiport --dports 80,443 -m time --timestart 18:00:00 --timestop 23:00:00

cheap "InfluxDB" -p tcp -m tcp --dport 8086
cheap "QUIC" -p udp -m udp --dport 443
fast "DNS" -p udp -m udp --dport 53
fast "Overwatch" -p tcp -m multiport --dports 1119,3724,6113
fast "UDP" -p udp
cheap "Default"

# Save for net boot
iptables-save > /etc/iptables/rules.v4
