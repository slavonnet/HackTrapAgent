FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      python3 \
      passwd \
      ca-certificates \
      openssl \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/log/smtp /opt/hacktrap/etc/smtp

COPY etc/smtp/ /opt/hacktrap/etc/smtp/
COPY build/smtp/entrypoint.sh /usr/local/bin/smtp-entrypoint.sh
COPY build/smtp/smtp_server.py /usr/local/bin/smtp_server.py

RUN chmod +x /usr/local/bin/smtp-entrypoint.sh

EXPOSE 25

ENTRYPOINT ["/usr/local/bin/smtp-entrypoint.sh"]
