FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      bash \
      strongswan \
      strongswan-pki \
      xl2tpd \
      ppp \
      procps \
      passwd \
      ca-certificates \
      openssl \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/log/ipsec /opt/hacktrap/etc/ipsec /run/hacktrap

COPY etc/ipsec/ /opt/hacktrap/etc/ipsec/
COPY build/ipsec/entrypoint.sh /usr/local/bin/ipsec-entrypoint.sh

RUN chmod +x /usr/local/bin/ipsec-entrypoint.sh

EXPOSE 1701/udp 500/udp 4500/udp

ENTRYPOINT ["/usr/local/bin/ipsec-entrypoint.sh"]
