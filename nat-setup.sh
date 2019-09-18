#!/bin/bash

iptables -t nat -F
iptables -t nat -A PREROUTING -d 192.168.8.1 -p tcp --dport 80 -j ACCEPT
iptables -t nat -A PREROUTING -s 192.168.8.100 -p tcp --dport 80 -j ACCEPT
iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination 192.168.5.1:3128
iptables -t nat -A POSTROUTING -j MASQUERADE
