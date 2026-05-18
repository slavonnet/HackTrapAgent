FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      redis-server \
      openssl \
      bash \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/hacktrap/etc/redis /var/log/redis /run/hacktrap

COPY etc/redis/ /opt/hacktrap/etc/redis/
COPY build/redis/entrypoint.sh /usr/local/bin/redis-entrypoint.sh

RUN chmod +x /usr/local/bin/redis-entrypoint.sh

EXPOSE 6379

ENTRYPOINT ["/usr/local/bin/redis-entrypoint.sh"]
