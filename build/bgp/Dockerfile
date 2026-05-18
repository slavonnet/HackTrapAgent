FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      bash \
      frr \
      ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/log/bgp /opt/hacktrap/etc/bgp /etc/frr

COPY etc/bgp/ /opt/hacktrap/etc/bgp/
COPY build/bgp/entrypoint.sh /usr/local/bin/bgp-entrypoint.sh

RUN chmod +x /usr/local/bin/bgp-entrypoint.sh

EXPOSE 179

ENTRYPOINT ["/usr/local/bin/bgp-entrypoint.sh"]
