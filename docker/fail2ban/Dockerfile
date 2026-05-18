FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      fail2ban \
      iptables \
      iproute2 \
      bash \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p \
      /etc/fail2ban/jail.d \
      /var/log/fail2ban \
      /var/run/fail2ban \
      /opt/hacktrap/local/fail2ban

COPY local/fail2ban/ /opt/hacktrap/local/fail2ban/
COPY docker/fail2ban/start.sh /usr/local/bin/fail2ban-entrypoint.sh

RUN chmod +x /usr/local/bin/fail2ban-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/fail2ban-entrypoint.sh"]
