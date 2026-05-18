FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      python3 \
      ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/log/bgp /opt/hacktrap/etc/bgp /opt/hacktrap/bgp

COPY etc/bgp/ /opt/hacktrap/etc/bgp/
COPY build/bgp/server.py /opt/hacktrap/bgp/server.py
COPY build/bgp/entrypoint.sh /usr/local/bin/bgp-entrypoint.sh

RUN chmod +x /usr/local/bin/bgp-entrypoint.sh

EXPOSE 179

ENTRYPOINT ["/usr/local/bin/bgp-entrypoint.sh"]
