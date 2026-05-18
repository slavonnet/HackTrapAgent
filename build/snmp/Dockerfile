FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      snmpd \
      snmp \
      procps \
      ca-certificates \
      openssl \
      bash \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/log/snmp /opt/hacktrap/etc/snmp /run/hacktrap /var/lib/snmp

COPY etc/snmp/ /opt/hacktrap/etc/snmp/
COPY build/snmp/entrypoint.sh /usr/local/bin/snmp-entrypoint.sh

RUN chmod +x /usr/local/bin/snmp-entrypoint.sh

EXPOSE 161/udp

ENTRYPOINT ["/usr/local/bin/snmp-entrypoint.sh"]
