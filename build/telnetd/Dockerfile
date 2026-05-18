FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      inetutils-telnetd \
      rsyslog \
      passwd \
      ca-certificates \
      openssl \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/log/telnet /opt/hacktrap/etc/telnetd /run/hacktrap

COPY etc/telnetd/rsyslog-telnet.conf /etc/rsyslog.d/30-telnet-auth.conf
COPY etc/telnetd/ /opt/hacktrap/etc/telnetd/
COPY build/telnetd/entrypoint.sh /usr/local/bin/telnetd-entrypoint.sh

RUN chmod +x /usr/local/bin/telnetd-entrypoint.sh

EXPOSE 23

ENTRYPOINT ["/usr/local/bin/telnetd-entrypoint.sh"]
