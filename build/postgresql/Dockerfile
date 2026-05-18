FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      postgresql \
      ca-certificates \
      openssl \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/hacktrap/etc/postgresql /run/hacktrap /var/log/postgresql

COPY etc/postgresql/ /opt/hacktrap/etc/postgresql/
COPY build/postgresql/entrypoint.sh /usr/local/bin/postgresql-entrypoint.sh

RUN chmod +x /usr/local/bin/postgresql-entrypoint.sh

EXPOSE 5432

ENTRYPOINT ["/usr/local/bin/postgresql-entrypoint.sh"]
