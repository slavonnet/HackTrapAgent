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
      /opt/hacktrap/fail2ban/common \
      /opt/hacktrap/fail2ban/ssh

COPY fail2ban/common/ /opt/hacktrap/fail2ban/common/
COPY fail2ban/ssh/ /opt/hacktrap/fail2ban/ssh/
COPY build/fail2ban/entrypoint.sh /usr/local/bin/fail2ban-entrypoint.sh

RUN chmod +x /usr/local/bin/fail2ban-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/fail2ban-entrypoint.sh"]
