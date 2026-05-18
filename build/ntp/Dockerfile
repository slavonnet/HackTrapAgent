FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      ntpsec \
      procps \
      ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/log/ntp /opt/hacktrap/etc/ntp

COPY build/ntp/entrypoint.sh /usr/local/bin/ntp-entrypoint.sh
COPY etc/ntp/ /opt/hacktrap/etc/ntp/

RUN chmod +x /usr/local/bin/ntp-entrypoint.sh

EXPOSE 123/udp

ENTRYPOINT ["/usr/local/bin/ntp-entrypoint.sh"]
