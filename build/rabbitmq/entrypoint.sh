#!/usr/bin/env bash
set -euo pipefail


restart_interval="${RESTART_INTERVAL_SECONDS:-1800}"
if [[ ! "$restart_interval" =~ ^[0-9]+$ ]] || [[ "$restart_interval" -lt 1 ]]; then
  restart_interval=1800
fi

(
  while true; do
    sleep "$restart_interval"
    kill -TERM 1 2>/dev/null || exit 0
  done
) &

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
chown -R rabbitmq:rabbitmq /var/log/rabbitmq
chmod 0644 /var/log/rabbitmq/rabbit.log

management_enabled_raw="${RABBITMQ_ENABLE_MANAGEMENT:-false}"
management_enabled="$(printf '%s' "$management_enabled_raw" | tr '[:upper:]' '[:lower:]')"

if [[ "$management_enabled" == "1" || "$management_enabled" == "true" || "$management_enabled" == "yes" ]]; then
  rabbitmq-plugins enable --offline rabbitmq_management >/dev/null
  echo "RabbitMQ management plugin enabled."
else
  rabbitmq-plugins disable --offline \
    rabbitmq_management \
    rabbitmq_management_agent \
    rabbitmq_web_dispatch \
    rabbitmq_prometheus >/dev/null || true
  echo "RabbitMQ management and metrics plugins disabled for low-CPU mode."
fi

if [[ -z "${RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS:-}" ]]; then
  export RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS="${RABBITMQ_LOW_CPU_ERL_ARGS:-+S 1:1 +A 2 +sbwt none +sbwtdcpu none +sbwtdio none}"
fi

ram_storage_raw="${RABBITMQ_UNSAFE_RAM_STORAGE:-true}"
ram_storage_enabled="$(printf '%s' "$ram_storage_raw" | tr '[:upper:]' '[:lower:]')"
if [[ "$ram_storage_enabled" == "1" || "$ram_storage_enabled" == "true" || "$ram_storage_enabled" == "yes" ]]; then
  export RABBITMQ_MNESIA_DIR="${RABBITMQ_MNESIA_DIR:-/dev/shm/rabbitmq/mnesia}"
  mkdir -p "$RABBITMQ_MNESIA_DIR"
  chown -R rabbitmq:rabbitmq "$(dirname "$RABBITMQ_MNESIA_DIR")"
  echo "RabbitMQ mnesia storage moved to RAM at ${RABBITMQ_MNESIA_DIR} (unsafe mode)."
fi

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
