#######################################################################
# Monitoring: most active clients

#/usr/local/bin/packetstats:
#  file.managed:
#    - source: salt://apps/router/packetstats.py
#    - mode: 755

/etc/systemd/system/packetstats@.service:
  file.managed:
    - source: salt://apps/router/packetstats.service

{%- for interface, addrs in grains['ip_interfaces'].items() if interface in ['eth0'] | sort %}
packetstats@{{ interface }}:
  service.running:
    - name: packetstats@{{ interface }}
    - enable: true
    - watch:
#      - file: /usr/local/bin/packetstats
      - file: /etc/systemd/system/packetstats@.service
{% endfor -%}

telegraf_packetstats:
  file.managed:
    - name: /etc/telegraf/telegraf.d/packetstats.conf
    - contents: |
        [[inputs.socket_listener]]
        service_address = "unixgram:///tmp/packetstats.sock"
        data_format = "influx"
