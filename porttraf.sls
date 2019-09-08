#######################################################################
# Monitoring: most active ports

/usr/local/bin/porttraf:
  file.managed:
    - source: salt://apps/router/porttraf.py
    - mode: 755

/etc/systemd/system/porttraf@.service:
  file.managed:
    - source: salt://apps/router/porttraf.service

porttraf_pkgs:
  pkg.installed:
    - pkgs:
      - python3-scapy

{%- for interface, addrs in grains['ip_interfaces'].items() if interface not in ['lo', 'eth0', 'wlan0'] | sort %}
porttraf@{{ interface }}:
  service.running:
    - name: porttraf@{{ interface }}
    - enable: true
    - watch:
      - file: /usr/local/bin/porttraf
      - file: /etc/systemd/system/porttraf@.service
{% endfor -%}

telegraf_porttraf:
  file.managed:
    - name: /etc/telegraf/telegraf.d/porttraf.conf
    - contents: |
        [[inputs.socket_listener]]
        service_address = "unixgram:///tmp/porttraf.sock"
        data_format = "influx"
