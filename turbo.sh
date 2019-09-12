#!/bin/sh
iptables -t mangle -I PREROUTING -j MARK --set-mark 4 -m comment --comment "Turbo!"
iptables -t mangle -I OUTPUT -j MARK --set-mark 4 -m comment --comment "Turbo!"
sleep 15m && /root/route-setup.sh &
