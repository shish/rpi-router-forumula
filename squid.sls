#######################################################################
# HTTP(s) Intercept: fetch html/js/css over the fast connection and
# fetch mkv/mp4/avi over the cheap connection/

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
