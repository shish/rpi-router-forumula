dhcpcd:
  pkg.installed:
    - name: dhcpcd5
  service.running:
    - watch:
      - file: dhcpcd
  file.blockreplace:
    - name: /etc/dhcpcd.conf
    - append_if_not_found: True
    - content: |
        interface wlan0
            static ip_address=192.168.4.1/24
            nohook wpa_supplicant
        interface eth0
            static ip_address=192.168.5.1/24
            nohook wpa_supplicant
    - require:
      - pkg: dhcpcd


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


## Uncomment if you want the raspberry pi to be a wifi access point.
## Personally I have a dedicated wifi AP connected via ethernet.
#hostapd:
#  pkg.installed:
#    - name: hostapd
#  service.running:
#    - watch:
#      - file: hostapd
#  file.managed:
#    - name: /etc/hostapd/hostapd.conf
#    - source: salt://apps/router/hostapd.conf
#    - require:
#      - pkg: hostapd


udev_rules:
  file.managed:
    - name: /etc/udev/rules.d/99-wwan.rules
    - source: salt://apps/router/wwan.rules


telegraf_uplinks:
  file.managed:
    - name: /etc/telegraf/telegraf.d/uplinks.conf
    - contents: |
{%- for interface, addrs in grains['ip_interfaces'].items() if interface not in ['lo', 'eth0', 'wlan0'] | sort %}
{%- for sample in range(10) %}
        [[inputs.ping]]
        urls = ["8.8.8.8"]
        count = 1
        timeout = 10.0
        deadline = 30
        interval = 60
        interface = "{{ interface }}"
        [inputs.ping.tags]
        sample = "{{ sample }}"
        interface = "{{ interface }}"
{% endfor -%}
{% endfor -%}


net.ipv4.ip_forward:
  sysctl.present:
    - value: 1


route-setup.sh:
  pkg.installed:
    - pkgs:
      - iptables-persistent
      - tcpdump  # for debugging
  file.managed:
    - name: /root/route-setup.sh
    - source: salt://apps/router/route-setup.sh
  cmd.wait:
    - name: /root/route-setup.sh
    - cwd: /root
    - runas: root
    - watch:
      - file: route-setup.sh


squid:
  pkg.installed:
    - name: squid
  service.running:
    - watch:
      - file: squid
  file.managed:
    - name: /etc/squid/conf.d/shishnet.conf
    - source: salt://apps/router/squid.conf

squid_cert_dir:
  file.directory:
    - name: /etc/squid/ssl_cert
    - user: proxy
    - group: proxy
    - mode: 700
# openssl req -new -newkey rsa:1024 -days 1365 -nodes -x509 -keyout myca.pem -out myca.pem
# openssl x509 -in myca.pem -outform DER -out myca.der

