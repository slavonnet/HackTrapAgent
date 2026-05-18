FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      tftpd-hpa \
      busybox \
      procps \
      ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/log/tftp /opt/hacktrap/etc/tftp /srv/tftp

COPY etc/tftp/tftpd.args /opt/hacktrap/etc/tftp/tftpd.args
COPY build/tftp/entrypoint.sh /usr/local/bin/tftp-entrypoint.sh

RUN chmod +x /usr/local/bin/tftp-entrypoint.sh

EXPOSE 69/udp

ENTRYPOINT ["/usr/local/bin/tftp-entrypoint.sh"]
