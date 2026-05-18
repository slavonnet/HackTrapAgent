FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      dovecot-core \
      dovecot-imapd \
      ca-certificates \
      openssl \
      procps \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/log/imap /opt/hacktrap/etc/imap

COPY etc/imap/ /opt/hacktrap/etc/imap/
COPY etc/imap/dovecot.conf /etc/dovecot/dovecot.conf
COPY build/imap/entrypoint.sh /usr/local/bin/imap-entrypoint.sh

RUN chmod +x /usr/local/bin/imap-entrypoint.sh

EXPOSE 143

ENTRYPOINT ["/usr/local/bin/imap-entrypoint.sh"]
