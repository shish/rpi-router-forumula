#######################################################################
# DHCP - 192.168.4.0/24 for wifi, 192.168.5.0/24 for ethernet
# DNS - with ad networks blacklisted

block-domains:
  file.managed:
    - name: /etc/block/domains
    - source: https://raw.githubusercontent.com/notracking/hosts-blocklists/master/domains.txt
    - skip_verify: True
    - makedirs: True

block-hosts:
  file.managed:
    - name: /etc/block/hosts
    - source: https://raw.githubusercontent.com/notracking/hosts-blocklists/master/hostnames.txt
    - skip_verify: True
    - makedirs: True

dnsmasq:
  pkg.installed:
    - name: dnsmasq
  service.running:
    - watch:
      - file: dnsmasq
  file.managed:
    - name: /etc/dnsmasq.conf
    - source: salt://apps/router/dnsmasq.conf
    - require:
      - pkg: dnsmasq
      - file: block-domains
      - file: block-hosts
