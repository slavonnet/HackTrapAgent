FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      python3 \
      procps \
      ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/log/ntp /opt/hacktrap/etc/ntp

COPY build/ntp/entrypoint.sh /usr/local/bin/ntp-entrypoint.sh
COPY build/ntp/ntp_honeypot.py /usr/local/bin/ntp-honeypot.py
COPY etc/ntp/ /opt/hacktrap/etc/ntp/

RUN chmod +x /usr/local/bin/ntp-entrypoint.sh /usr/local/bin/ntp-honeypot.py

EXPOSE 123/udp

ENTRYPOINT ["/usr/local/bin/ntp-entrypoint.sh"]
