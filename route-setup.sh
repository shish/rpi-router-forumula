#!/bin/bash

ip route flush table 4
ip route show table main | grep -v default | grep -v wwanT | while read ROUTE ; do
    ip route add table 4 $ROUTE
done
ip route add table 4 default via 192.168.8.1 dev wwanV
ip rule | grep -q 'fwmark 0x4' || ip rule add fwmark 4 lookup 4

ip route flush table 3
ip route show table main | grep -v default | grep -v wwanV | while read ROUTE ; do
    ip route add table 3 $ROUTE
done
ip route add table 3 default via 192.168.8.1 dev wwanT
ip rule | grep -q 'fwmark 0x3' || ip rule add fwmark 3 lookup 3

# With the above setup, any packets marked 3 go to wwanT and
# any marked 4 go to wwantV. The next script will use a bunch
# of iptables rules to mark packets.
bash /root/mangle-setup.sh

# We also want to do some magic to mark HTTP packets
bash /root/nat-setup.sh
