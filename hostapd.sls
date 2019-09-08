#######################################################################
# HostAPd config for raspberry pi

hostapd:
  pkg.installed:
    - name: hostapd
  service.running:
    - watch:
      - file: hostapd
  file.managed:
    - name: /etc/hostapd/hostapd.conf
    - source: salt://apps/router/hostapd.conf
    - require:
      - pkg: hostapd
