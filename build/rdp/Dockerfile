FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      xrdp \
      openssl \
      passwd \
      ca-certificates \
      procps \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/log/rdp /opt/hacktrap/etc/rdp /run/hacktrap /var/run/xrdp

COPY etc/rdp/ /opt/hacktrap/etc/rdp/
COPY build/rdp/entrypoint.sh /usr/local/bin/rdp-entrypoint.sh

RUN chmod +x /usr/local/bin/rdp-entrypoint.sh

EXPOSE 3389

ENTRYPOINT ["/usr/local/bin/rdp-entrypoint.sh"]
