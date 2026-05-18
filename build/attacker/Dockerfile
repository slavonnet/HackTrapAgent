FROM alpine:3.20

RUN apk add --no-cache \
      bash \
      iproute2 \
      lftp \
      mariadb-client \
      netcat-openbsd \
      openssh-client \
      py3-pip \
      python3 \
      strongswan \
      postgresql-client \
      sshpass \
    && pip3 install --no-cache-dir --break-system-packages pymongo

CMD ["sleep", "infinity"]
