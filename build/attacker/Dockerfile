FROM alpine:3.20

RUN apk add --no-cache \
      bash \
      hydra \
      freeradius-client \
      freeradius-utils \
      busybox-extras \
      iproute2 \
      lftp \
      mariadb-client \
      netcat-openbsd \
      net-snmp-tools \
      nfs-utils \
      openldap-clients \
      openssh-client \
      py3-pip \
      rabbitmq-c-utils \
      python3 \
      redis \
      strongswan \
      postgresql-client \
      sshpass \
      util-linux \
    && pip3 install --no-cache-dir --break-system-packages pymongo

CMD ["sleep", "infinity"]
