FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      slapd \
      ldap-utils \
      rsyslog \
      passwd \
      ca-certificates \
      openssl \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/log/ad /opt/hacktrap/etc/ad /run/slapd /var/lib/ldap

COPY etc/ad/ /opt/hacktrap/etc/ad/
COPY build/ad/entrypoint.sh /usr/local/bin/ad-entrypoint.sh

RUN chmod +x /usr/local/bin/ad-entrypoint.sh

EXPOSE 389

ENTRYPOINT ["/usr/local/bin/ad-entrypoint.sh"]
