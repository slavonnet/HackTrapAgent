FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      dovecot-core \
      dovecot-pop3d \
      ca-certificates \
      openssl \
      procps \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/log/pop3 /opt/hacktrap/etc/pop3

COPY etc/pop3/ /opt/hacktrap/etc/pop3/
COPY etc/pop3/dovecot.conf /etc/dovecot/dovecot.conf
COPY build/pop3/entrypoint.sh /usr/local/bin/pop3-entrypoint.sh

RUN chmod +x /usr/local/bin/pop3-entrypoint.sh

EXPOSE 110

ENTRYPOINT ["/usr/local/bin/pop3-entrypoint.sh"]
