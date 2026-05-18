FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      nfs-ganesha \
      nfs-ganesha-vfs \
      rpcbind \
      procps \
      gettext-base \
      ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/log/nfs /var/run/ganesha /srv/nfs/export /opt/hacktrap/etc/nfs

COPY etc/nfs/ganesha.conf.tpl /opt/hacktrap/etc/nfs/ganesha.conf.tpl
COPY build/nfs/entrypoint.sh /usr/local/bin/nfs-entrypoint.sh

RUN chmod +x /usr/local/bin/nfs-entrypoint.sh

EXPOSE 2049

ENTRYPOINT ["/usr/local/bin/nfs-entrypoint.sh"]
