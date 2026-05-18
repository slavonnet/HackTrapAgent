FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      samba \
      passwd \
      openssl \
      ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/log/smb /srv/smb/trapshare /opt/hacktrap/etc/smb /run/samba

COPY etc/smb/smb.conf /etc/samba/smb.conf
COPY etc/smb/ /opt/hacktrap/etc/smb/
COPY build/smb/entrypoint.sh /usr/local/bin/smb-entrypoint.sh

RUN chmod +x /usr/local/bin/smb-entrypoint.sh

EXPOSE 445

ENTRYPOINT ["/usr/local/bin/smb-entrypoint.sh"]
