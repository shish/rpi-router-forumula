#!/bin/bash

# Note that TOS bits 1/2 are used for other things, so we use 4/8
ip route | grep -q 'tos 0x04' || ip route add default tos 0x04 via 192.168.8.1 dev wwanV
ip route | grep -q 'tos 0x08' || ip route add default tos 0x08 via 192.168.8.1 dev wwanT

# With the above setup, any packets marked 3 go to wwanT and
# any marked 4 go to wwantV. The next script will use a bunch
# of iptables rules to mark packets.
bash /root/mangle-setup.sh

# We also want to do some magic to mark HTTP packets
bash /root/nat-setup.sh
