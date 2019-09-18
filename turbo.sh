#!/bin/sh
iptables -t mangle -I marking -j vodafone -m comment --comment "Turbo!"
sleep 15m && /root/mangle-setup.sh &
