#!/usr/bin/env bash
set -euo pipefail

user_name="${HACKTRAP_USER:-trap}"
users_file="/opt/hacktrap/etc/rabbitmq/users.conf"

if [[ -f "$users_file" ]]; then
  while IFS=: read -r cfg_user _; do
    [[ -z "${cfg_user// }" ]] && continue
    [[ "${cfg_user:0:1}" == "#" ]] && continue
    user_name="$cfg_user"
    break
  done < "$users_file"
fi

if [[ ! "$user_name" =~ ^[A-Za-z0-9_]+$ ]]; then
  echo "Invalid RabbitMQ runtime user: '$user_name'"
  exit 1
fi

service_password="$(openssl rand -hex 24)"
credentials_file="/run/hacktrap/rabbitmq_credentials.env"

mkdir -p /run/hacktrap /var/log/rabbitmq
touch /var/log/rabbitmq/rabbit.log
chmod 0644 /var/log/rabbitmq/rabbit.log

{
  printf "RABBITMQ_SERVICE_USER=%s\n" "$user_name"
  printf "RABBITMQ_SERVICE_PASSWORD=%s\n" "$service_password"
} > "$credentials_file"
chmod 600 "$credentials_file"
echo "Generated random RabbitMQ runtime password."

export RABBITMQ_DEFAULT_USER="$user_name"
export RABBITMQ_DEFAULT_PASS="$service_password"
export RABBITMQ_LOGS="${RABBITMQ_LOGS:-/var/log/rabbitmq/rabbit.log}"

exec /usr/local/bin/docker-entrypoint.sh rabbitmq-server
