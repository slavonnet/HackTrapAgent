FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      mariadb-server \
      openssl \
      ca-certificates \
      bash \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/log/mysql /run/mysqld /opt/hacktrap/etc/mysql

COPY etc/mysql/mariadb-hacktrap.cnf /etc/mysql/mariadb.conf.d/99-hacktrap.cnf
COPY etc/mysql/ /opt/hacktrap/etc/mysql/
COPY build/mysql/entrypoint.sh /usr/local/bin/mysql-entrypoint.sh

RUN chmod +x /usr/local/bin/mysql-entrypoint.sh

EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/mysql-entrypoint.sh"]
