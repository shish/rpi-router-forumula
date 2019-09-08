Home Router Setup
-----------------

Context:
========

- My home doesn't get fiber internet, and landline broadband is awful :(
- Mobile internet from Vodafone is fast (100mbps), but capped at 150GB/mo
- Mobile internet from Three is slow (1mbps on a good day, 200kbps normally), but uncapped

So I bought a pair of SIMs, a pair of USB 4G dongles, and a raspberry pi.

The overall network looks like this:

```
            Three Dongle            Vodafone Dongle
            192.168.8.1               192.168.8.1
                 |                          |
                 |                          |
           192.168.8.100 (wwanT)    192.168.8.100 (wwanV)
                           raspberry pi
           192.168.4.1 (wlan0)       192.168.5.1 (eth0)
               |  |  |                      |
               |  |  |                      |
            (optional                ethernet switch
              wifi clients)          |      |      |
                                    NAS   Media   UniFi
                                          Center   AP
                                                   |
                                                   |
                                              (wifi clients)
```

Originally I had the raspberry pi serving wifi and ethernet; which worked ok
for internet access, but was a bottleneck on accessing the NAS. So I got a
dedicated WiFi AP and plgged that into the switch -- so now the pi only handles
internet routing, and is out of the path for local routing.

Something that has made this setup a lot trickier is that the wifi dongles I
bought (Huawei E3372) have a fixed IP address and give a fixed IP address to
clients - so I need to route traffic via network interface name rather than
by binding to an outgoing IP address.

Something that made THAT a lot harder is that the wifi dongles are
non-deterministic such that which one is wwan0 and which one is wwan1 is
random. So one would think that Linux's new "consistent network interface"
names would solve that, right? Normally yes - but in the case of USB dongles,
linux achieves consistency by using the dongle's MAC address as the device
name... and both of these dongles have the same MAC address, hard-coded into
them :|

So, I ended up using udev rules to assign network interface names based on
which USB port is in use - the upper usb3 port is wwanV (Vodafone), and the
lower usb3 port is wwanT (Three).


The Actual Routing:
===================

Given two upstream interfaces, I then do:

- `iptables` rules to mark packets as "3" (Three) or "4" (Vodafone)
- `ip rule` says packets marked with 3 should use routing table 3, and 4 with 4
- `ip route` sets up two routing tables - table 3 contains
  `default via 192.168.8.1 dev wwanT`, and table 4 uses `dev wwanV`


HTTP(S):
========

iptables rules can filter different kinds of IP packets, but in today's world
basically every kind of packet is a HTTP packet. To deal with this, I have
squid set up in transparent intercept mode - iptables rules will redirect all
outgoing port 80 traffic into squid, where squid will apply various HTTP-based
rules (URL, domain name, etc) and then forward the request upstream with each
packet marked "3" or "4" depending on whether we want fast or cheap.

HTTPS intercept should be possible, but is work-in-progress.


Turbo Button:
=============

TODO: Have a button on the pi which will route ALL traffic via the fast
connection, for 15 minutes, then automatically reset to default routes.
