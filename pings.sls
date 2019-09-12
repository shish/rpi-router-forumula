#######################################################################
# Monitoring: latency heatmap per upstream

telegraf_uplinks:
  file.managed:
    - name: /etc/telegraf/telegraf.d/uplinks.conf
    - contents: |
{%- for interface, addrs in grains['ip_interfaces'].items() if interface not in ['lo', 'eth0', 'wlan0'] | sort %}
{%- for sample in range(10) %}
        [[inputs.ping]]
        urls = ["8.8.8.8"]
        count = 1
        timeout = 5.0
        deadline = 8
        interval = 60
        interface = "{{ interface }}"
        [inputs.ping.tags]
        sample = "{{ sample }}"
        interface = "{{ interface }}"
{% endfor -%}
{% endfor -%}
