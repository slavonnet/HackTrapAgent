FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      postfix \
      sasl2-bin \
      libsasl2-modules \
      procps \
      ca-certificates \
      openssl \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/log/smtp /opt/hacktrap/etc/smtp

COPY etc/smtp/ /opt/hacktrap/etc/smtp/
COPY etc/smtp/main.cf /etc/postfix/main.cf
COPY etc/smtp/smtpd.conf /etc/postfix/sasl/smtpd.conf
COPY build/smtp/entrypoint.sh /usr/local/bin/smtp-entrypoint.sh

RUN chmod +x /usr/local/bin/smtp-entrypoint.sh

EXPOSE 25

ENTRYPOINT ["/usr/local/bin/smtp-entrypoint.sh"]
