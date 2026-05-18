FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      samba \
      passwd \
      ca-certificates \
      openssl \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/log/ad /srv/ad/share /opt/hacktrap/etc/ad /run/samba

COPY etc/ad/smb.conf /etc/samba/smb.conf
COPY etc/ad/ /opt/hacktrap/etc/ad/
COPY build/ad/entrypoint.sh /usr/local/bin/ad-entrypoint.sh

RUN chmod +x /usr/local/bin/ad-entrypoint.sh

EXPOSE 445

ENTRYPOINT ["/usr/local/bin/ad-entrypoint.sh"]
