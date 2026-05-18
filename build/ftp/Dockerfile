FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      vsftpd \
      passwd \
      ca-certificates \
      openssl \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/log/ftp /opt/hacktrap/etc/ftp /run/vsftpd/empty

COPY etc/ftp/vsftpd.conf /etc/vsftpd.conf
COPY etc/ftp/ /opt/hacktrap/etc/ftp/
COPY build/ftp/entrypoint.sh /usr/local/bin/ftp-entrypoint.sh

RUN chmod +x /usr/local/bin/ftp-entrypoint.sh

EXPOSE 21

ENTRYPOINT ["/usr/local/bin/ftp-entrypoint.sh"]
