#!/usr/bin/env bash
set -euo pipefail

user_name="${HACKTRAP_USER:-trap}"
users_file="/opt/hacktrap/etc/kafka/users.conf"

if [[ -f "$users_file" ]]; then
  while IFS=':' read -r cfg_user _; do
    [[ -z "${cfg_user// }" ]] && continue
    [[ "${cfg_user:0:1}" == "#" ]] && continue
    user_name="$cfg_user"
    break
  done < "$users_file"
fi

auth_password="$(openssl rand -hex 24)"

mkdir -p /run/hacktrap /var/log/kafka
credentials_file="/run/hacktrap/kafka_credentials.env"
{
  printf "KAFKA_AUTH_USER=%s\n" "$user_name"
  printf "KAFKA_AUTH_PASSWORD=%s\n" "$auth_password"
} > "$credentials_file"
chmod 600 "$credentials_file"
echo "Generated random Kafka honeypot credentials."

touch /var/log/kafka/kafka.log
chmod 0644 /var/log/kafka/kafka.log

export KAFKA_HONEYPOT_USER="$user_name"

exec socat -T5 TCP-LISTEN:9092,reuseaddr,fork EXEC:/usr/local/bin/kafka-log-attempt.sh
