FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      openssh-server \
      rsyslog \
      passwd \
      ca-certificates \
      openssl \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /run/sshd /var/log/ssh /opt/hacktrap/etc/ssh

COPY etc/ssh/sshd_config /etc/ssh/sshd_config
COPY etc/ssh/rsyslog-sshd.conf /etc/rsyslog.d/00-sshd.conf
COPY build/ssh/entrypoint.sh /usr/local/bin/ssh-entrypoint.sh
COPY etc/ssh/ /opt/hacktrap/etc/ssh/

RUN chmod +x /usr/local/bin/ssh-entrypoint.sh

EXPOSE 22

ENTRYPOINT ["/usr/local/bin/ssh-entrypoint.sh"]
