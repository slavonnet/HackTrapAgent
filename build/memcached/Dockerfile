FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      memcached \
      python3 \
      openssl \
      ca-certificates \
      bash \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/log/memcached /opt/hacktrap/etc/memcached /run/hacktrap

COPY etc/memcached/ /opt/hacktrap/etc/memcached/
COPY build/memcached/entrypoint.sh /usr/local/bin/memcached-entrypoint.sh
COPY build/memcached/auth_proxy.py /usr/local/bin/memcached-auth-proxy.py

RUN chmod +x /usr/local/bin/memcached-entrypoint.sh /usr/local/bin/memcached-auth-proxy.py

EXPOSE 11211

ENTRYPOINT ["/usr/local/bin/memcached-entrypoint.sh"]
