FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      freeradius \
      ca-certificates \
      openssl \
      procps \
      bash \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/log/radius /opt/hacktrap/etc/radius /run/hacktrap

COPY etc/radius/ /opt/hacktrap/etc/radius/
COPY build/radius/entrypoint.sh /usr/local/bin/radius-entrypoint.sh

RUN chmod +x /usr/local/bin/radius-entrypoint.sh

EXPOSE 1812/udp

ENTRYPOINT ["/usr/local/bin/radius-entrypoint.sh"]
