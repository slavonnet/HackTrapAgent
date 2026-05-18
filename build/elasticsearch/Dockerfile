FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      python3 \
      openssl \
      ca-certificates \
      bash \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/log/elasticsearch /opt/hacktrap/etc/elasticsearch /opt/hacktrap/elasticsearch /run/hacktrap

COPY etc/elasticsearch/ /opt/hacktrap/etc/elasticsearch/
COPY build/elasticsearch/server.py /opt/hacktrap/elasticsearch/server.py
COPY build/elasticsearch/entrypoint.sh /usr/local/bin/elasticsearch-entrypoint.sh

RUN chmod +x /usr/local/bin/elasticsearch-entrypoint.sh

EXPOSE 9200

ENTRYPOINT ["/usr/local/bin/elasticsearch-entrypoint.sh"]
