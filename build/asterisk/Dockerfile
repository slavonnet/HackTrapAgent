FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      asterisk \
      asterisk-modules \
      ca-certificates \
      openssl \
      procps \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/hacktrap/etc/asterisk /run/hacktrap /var/log/asterisk

COPY etc/asterisk/ /opt/hacktrap/etc/asterisk/
COPY build/asterisk/entrypoint.sh /usr/local/bin/asterisk-entrypoint.sh

RUN chmod +x /usr/local/bin/asterisk-entrypoint.sh

EXPOSE 5060/tcp 5060/udp 4569/udp 5038 8088

ENTRYPOINT ["/usr/local/bin/asterisk-entrypoint.sh"]
