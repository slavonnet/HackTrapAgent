FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      openssh-server \
      rsyslog \
      passwd \
      ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /run/sshd /var/log/ssh /opt/hacktrap/local/ssh

COPY docker/ssh/sshd_config /etc/ssh/sshd_config
COPY docker/ssh/rsyslog-sshd.conf /etc/rsyslog.d/00-sshd.conf
COPY docker/ssh/entrypoint.sh /usr/local/bin/ssh-entrypoint.sh
COPY local/ssh/ /opt/hacktrap/local/ssh/

RUN chmod +x /usr/local/bin/ssh-entrypoint.sh

EXPOSE 22

ENTRYPOINT ["/usr/local/bin/ssh-entrypoint.sh"]
