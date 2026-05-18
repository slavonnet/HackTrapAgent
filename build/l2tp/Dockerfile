FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      bash \
      socat \
      procps \
      passwd \
      ca-certificates \
      openssl \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/log/l2tp /opt/hacktrap/etc/l2tp /run/hacktrap

COPY etc/l2tp/ /opt/hacktrap/etc/l2tp/
COPY build/l2tp/entrypoint.sh /usr/local/bin/l2tp-entrypoint.sh
COPY build/l2tp/log_packet.sh /usr/local/bin/l2tp-log-packet.sh

RUN chmod +x /usr/local/bin/l2tp-entrypoint.sh /usr/local/bin/l2tp-log-packet.sh

EXPOSE 1701/udp

ENTRYPOINT ["/usr/local/bin/l2tp-entrypoint.sh"]
