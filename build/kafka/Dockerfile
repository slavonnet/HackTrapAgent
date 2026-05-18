FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      socat \
      openssl \
      ca-certificates \
      bash \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/log/kafka /opt/hacktrap/etc/kafka /run/hacktrap

COPY etc/kafka/ /opt/hacktrap/etc/kafka/
COPY build/kafka/entrypoint.sh /usr/local/bin/kafka-entrypoint.sh
COPY build/kafka/log_attempt.sh /usr/local/bin/kafka-log-attempt.sh

RUN chmod +x /usr/local/bin/kafka-entrypoint.sh /usr/local/bin/kafka-log-attempt.sh

EXPOSE 9092

ENTRYPOINT ["/usr/local/bin/kafka-entrypoint.sh"]
