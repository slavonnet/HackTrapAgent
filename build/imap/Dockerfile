FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      python3 \
      passwd \
      ca-certificates \
      openssl \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/log/imap /opt/hacktrap/etc/imap

COPY etc/imap/ /opt/hacktrap/etc/imap/
COPY build/imap/entrypoint.sh /usr/local/bin/imap-entrypoint.sh
COPY build/imap/imap_server.py /usr/local/bin/imap_server.py

RUN chmod +x /usr/local/bin/imap-entrypoint.sh

EXPOSE 143

ENTRYPOINT ["/usr/local/bin/imap-entrypoint.sh"]
