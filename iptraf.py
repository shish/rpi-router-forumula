#!/usr/bin/env python3
import scapy.all as scapy
import argparse
import sys
import time
import socket
from collections import defaultdict


ip_send = defaultdict(int)
ip_recv = defaultdict(int)
rdns = None

MYMAC = None
last_print = time.time()
interval = 10

def write_to(fn, msg):
    try:
        client = socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM)
        client.connect(fn)
        client.send(msg.encode('ascii'))
    except Exception as e:
        print("Error writing stats to socket: %s" % e)
        print(msg)


def dict2str(packets):
    return ",".join(f"{host}={octets}" for host, octets in packets.items())


def print_stats(name, iface, packets):
    if packets:
        write_to(
            f"/tmp/iptraf.sock", 
            f"iptraf,counter={name},interface={iface} %s" % dict2str(packets)
        )


def lookup(ip):
    try:
        if rdns is not None:
            if ip not in rdns:
                rdns[ip] = socket.gethostbyaddr(ip)[0]
            return rdns[ip]
    except Exception as e:
        print(f"Error getting reverse DNS for {ip}: {e}")
    return ip


def count(packet):
    global last_print

    if packet.haslayer(scapy.IP):
        ip = packet.getlayer(scapy.IP)
        if packet.src == MYMAC:
            ip_send[lookup(ip.dst)] += len(packet)
        else:
            ip_recv[lookup(ip.src)] += len(packet)

    if time.time() > last_print + interval:
        last_print = time.time()
        print_stats("recv", packet.sniffed_on, ip_recv)
        print_stats("send", packet.sniffed_on, ip_send)


def main(argv):
    global MYMAC, rdns

    parser = argparse.ArgumentParser()
    parser.add_argument("-i", "--interface", default="eno1")
    parser.add_argument("-r", "--rdns", action="store_true", default=False)
    args = parser.parse_args(argv[1:])

    MYMAC = scapy.get_if_hwaddr(args.interface)
    if args.rdns:
        rdns = {}

    scapy.sniff(iface=args.interface, store=False, prn=count)


if __name__ == "__main__":
    sys.exit(main(sys.argv))
