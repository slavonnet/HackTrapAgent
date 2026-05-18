FROM clickhouse/clickhouse-server:24.8

USER root

RUN mkdir -p \
      /opt/hacktrap/etc/clickhouse \
      /run/hacktrap \
      /var/log/clickhouse-server \
      /etc/clickhouse-server/users.d \
      /etc/clickhouse-server/config.d

COPY etc/clickhouse/ /opt/hacktrap/etc/clickhouse/
COPY build/clickhouse/entrypoint.sh /usr/local/bin/clickhouse-entrypoint.sh

RUN chmod +x /usr/local/bin/clickhouse-entrypoint.sh \
    && chown -R clickhouse:clickhouse \
      /opt/hacktrap/etc/clickhouse \
      /run/hacktrap \
      /var/log/clickhouse-server \
      /etc/clickhouse-server/users.d \
      /etc/clickhouse-server/config.d

EXPOSE 8123 9000

ENTRYPOINT ["/usr/local/bin/clickhouse-entrypoint.sh"]
CMD ["clickhouse-server", "--config-file=/etc/clickhouse-server/config.xml"]
