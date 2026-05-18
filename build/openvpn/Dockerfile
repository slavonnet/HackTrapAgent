FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      socat \
      iproute2 \
      ca-certificates \
      openssl \
      bash \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/log/openvpn /opt/hacktrap/etc/openvpn /run/hacktrap

COPY etc/openvpn/ /opt/hacktrap/etc/openvpn/
COPY build/openvpn/entrypoint.sh /usr/local/bin/openvpn-entrypoint.sh
COPY build/openvpn/log_attempt.sh /usr/local/bin/openvpn-log-attempt.sh

RUN chmod +x /usr/local/bin/openvpn-entrypoint.sh /usr/local/bin/openvpn-log-attempt.sh

EXPOSE 1194/udp

ENTRYPOINT ["/usr/local/bin/openvpn-entrypoint.sh"]
