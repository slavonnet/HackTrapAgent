FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      snmp \
      snmptrapd \
      procps \
      ca-certificates \
      openssl \
      bash \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/log/snmptrap /opt/hacktrap/etc/snmptrap /run/hacktrap /var/lib/snmp

COPY etc/snmptrap/ /opt/hacktrap/etc/snmptrap/
COPY build/snmptrap/entrypoint.sh /usr/local/bin/snmptrap-entrypoint.sh

RUN chmod +x /usr/local/bin/snmptrap-entrypoint.sh

EXPOSE 162/udp

ENTRYPOINT ["/usr/local/bin/snmptrap-entrypoint.sh"]
