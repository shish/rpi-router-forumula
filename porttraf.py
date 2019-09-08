#!/usr/bin/env python3
import scapy.all as scapy
import argparse
import sys
import time
import socket
from collections import defaultdict


proto = defaultdict(int)
ports_recv_from = {}
ports_recv_to = {}
ports_send_from = {}
ports_send_to = {}

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
    return ",".join(f"{port}={octets}" for port, octets in packets.items())


def print_stats(name, iface, packets):
    if packets:
        write_to(
            f"/tmp/porttraf.sock", 
            f"porttraf,counter={name},interface={iface} %s" % dict2str(packets)
        )


def count(packet):
    global last_print

    if packet.haslayer(scapy.TCP):
        if packet.src == MYMAC:
            proto["tcp-send"] += len(packet)
        else:
            proto["tcp-recv"] += len(packet)
    elif packet.haslayer(scapy.UDP):
        if packet.src == MYMAC:
            proto["udp-send"] += len(packet)
        else:
            proto["udp-recv"] += len(packet)
    else:
        if packet.src == MYMAC:
            proto["oth-send"] += len(packet)
        else:
            proto["oth-recv"] += len(packet)

    if packet.haslayer(scapy.TCP):
        ip = packet.getlayer(scapy.IP)
        tcp = packet.getlayer(scapy.TCP)
        # print(f"{ip.src}:{tcp.sport} -> {ip.dst}:{tcp.dport} :: {tcp.flags}")

        if packet.src == MYMAC:
            # If this is a new outgoing connection, begin counting packets to
            # the dport and form the dport
            if tcp.flags == "S":
                if tcp.dport not in ports_send_to:
                    print(f"New remote port: {tcp.dport}")
                    ports_send_to.setdefault(tcp.dport, 0)
                    ports_recv_from.setdefault(tcp.dport, 0)
            # If we're responding to a new connection request, then mark that
            # port as open locally
            if tcp.flags == "SA":
                if tcp.sport not in ports_recv_to:
                    print(f"New local port: {tcp.sport}")
                    # print(f"{ip.src}:{tcp.sport} -> {ip.dst}:{tcp.dport} :: {tcp.flags}")
                    ports_recv_to.setdefault(tcp.sport, 0)
                    ports_send_from.setdefault(tcp.sport, 0)
            if tcp.sport in ports_send_from:
                ports_send_from[tcp.sport] += len(packet)
            if tcp.dport in ports_send_to:
                ports_send_to[tcp.dport] += len(packet)
        if packet.dst == MYMAC:
            if tcp.sport in ports_recv_from:
                ports_recv_from[tcp.sport] += len(packet)
            if tcp.dport in ports_recv_to:
                ports_recv_to[tcp.dport] += len(packet)

    if time.time() > last_print + interval:
        last_print = time.time()
        write_to(
            f"/tmp/porttraf.sock", 
            f"prototraf,interface={packet.sniffed_on} %s" % dict2str(proto)
        )
        print_stats("recv_from", packet.sniffed_on, ports_recv_from)
        print_stats("recv_to", packet.sniffed_on, ports_recv_to)
        print_stats("send_from", packet.sniffed_on, ports_send_from)
        print_stats("send_to", packet.sniffed_on, ports_send_to)


def main(argv):
    global MYMAC

    parser = argparse.ArgumentParser()
    parser.add_argument("-i", "--interface", default="eno1")
    args = parser.parse_args(argv[1:])

    MYMAC = scapy.get_if_hwaddr(args.interface)

    scapy.sniff(iface=args.interface, store=False, prn=count)


if __name__ == "__main__":
    sys.exit(main(sys.argv))
