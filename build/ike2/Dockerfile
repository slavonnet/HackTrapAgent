FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      bash \
      strongswan \
      strongswan-pki \
      procps \
      passwd \
      ca-certificates \
      openssl \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/log/ike2 /opt/hacktrap/etc/ike2 /run/hacktrap

COPY etc/ike2/ /opt/hacktrap/etc/ike2/
COPY build/ike2/entrypoint.sh /usr/local/bin/ike2-entrypoint.sh

RUN chmod +x /usr/local/bin/ike2-entrypoint.sh

EXPOSE 500/udp 4500/udp

ENTRYPOINT ["/usr/local/bin/ike2-entrypoint.sh"]
