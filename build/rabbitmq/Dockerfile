FROM rabbitmq:4-management

RUN mkdir -p /opt/hacktrap/etc/rabbitmq /var/log/rabbitmq /run/hacktrap

COPY etc/rabbitmq/ /opt/hacktrap/etc/rabbitmq/
COPY build/rabbitmq/entrypoint.sh /usr/local/bin/hacktrap-rabbitmq-entrypoint.sh

RUN chmod +x /usr/local/bin/hacktrap-rabbitmq-entrypoint.sh

EXPOSE 5672 15672

ENTRYPOINT ["/usr/local/bin/hacktrap-rabbitmq-entrypoint.sh"]
