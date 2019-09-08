#######################################################################
# Monitoring: most active clients

/usr/local/bin/iptraf:
  file.managed:
    - source: salt://apps/router/iptraf.py
    - mode: 755

/etc/systemd/system/iptraf@.service:
  file.managed:
    - source: salt://apps/router/iptraf.service

iptraf_pkgs:
  pkg.installed:
    - pkgs:
      - python3-scapy

{%- for interface, addrs in grains['ip_interfaces'].items() if interface in ['eth0'] | sort %}
iptraf@{{ interface }}:
  service.running:
    - name: iptraf@{{ interface }}
    - enable: true
    - watch:
      - file: /usr/local/bin/iptraf
      - file: /etc/systemd/system/iptraf@.service
{% endfor -%}

telegraf_iptraf:
  file.managed:
    - name: /etc/telegraf/telegraf.d/iptraf.conf
    - contents: |
        [[inputs.socket_listener]]
        service_address = "unixgram:///tmp/iptraf.sock"
        data_format = "influx"
