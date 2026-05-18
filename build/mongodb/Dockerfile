FROM mongo:8.0

RUN mkdir -p /opt/hacktrap/etc/mongodb /run/hacktrap /var/log/mongodb

COPY etc/mongodb/ /opt/hacktrap/etc/mongodb/
COPY build/mongodb/entrypoint.sh /usr/local/bin/mongodb-entrypoint.sh

RUN chmod +x /usr/local/bin/mongodb-entrypoint.sh

EXPOSE 27017

ENTRYPOINT ["/usr/local/bin/mongodb-entrypoint.sh"]
