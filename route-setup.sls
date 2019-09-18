#######################################################################
# Config files to turn a raspberry pi into a router with two upstreams

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


udev_rules:
  file.managed:
    - name: /etc/udev/rules.d/99-wwan.rules
    - source: salt://apps/router/wwan.rules


net.ipv4.ip_forward:
  sysctl.present:
    - value: 1

router_debug_things:
  pkg.installed:
    - pkgs:
      - iptables-persistent
      - tcpdump  # for debugging

nat-setup.sh:
  file.managed:
    - name: /root/nat-setup.sh
    - source: salt://apps/router/nat-setup.sh

mangle-setup.sh:
  file.managed:
    - name: /root/mangle-setup.sh
    - source: salt://apps/router/mangle-setup.sh

route-setup.sh:
  file.managed:
    - name: /root/route-setup.sh
    - source: salt://apps/router/route-setup.sh
  cmd.wait:
    - name: /root/route-setup.sh
    - cwd: /root
    - runas: root
    - watch:
      - file: route-setup.sh
      - file: mangle-setup.sh
      - file: nat-setup.sh

turbo.sh:
  file.managed:
    - name: /root/turbo.sh
    - source: salt://apps/router/turbo.sh
