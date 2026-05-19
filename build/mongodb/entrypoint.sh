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
users_file="/opt/hacktrap/etc/mongodb/users.conf"
mongo_data_dir="/data/db"
mongo_log_dir="/var/log/mongodb"
mongo_log_file="${mongo_log_dir}/mongodb.log"
mongo_port="${MONGODB_PORT:-27017}"

if [[ -f "$users_file" ]]; then
  while IFS=: read -r cfg_user _; do
    [[ -z "${cfg_user// }" ]] && continue
    [[ "${cfg_user:0:1}" == "#" ]] && continue
    user_name="$cfg_user"
    break
  done < "$users_file"
fi

if [[ ! "$user_name" =~ ^[A-Za-z0-9_]+$ ]]; then
  echo "Invalid mongodb runtime user: '$user_name'"
  exit 1
fi

js_escape_single_quoted() {
  printf "%s" "$1" | sed "s/\\\\/\\\\\\\\/g; s/'/\\\\'/g"
}

mkdir -p "$mongo_data_dir" "$mongo_log_dir" /run/hacktrap
rm -rf "${mongo_data_dir:?}/"*
touch "$mongo_log_file"
chown -R mongodb:mongodb "$mongo_data_dir" "$mongo_log_dir"

root_password="$(openssl rand -hex 24)"
service_password=""
if [[ "$user_name" != "root" ]]; then
  service_password="$(openssl rand -hex 24)"
fi

root_password_js="$(js_escape_single_quoted "$root_password")"
user_name_js="$(js_escape_single_quoted "$user_name")"
service_password_js="$(js_escape_single_quoted "$service_password")"

gosu mongodb mongod \
  --dbpath "$mongo_data_dir" \
  --bind_ip 127.0.0.1 \
  --port "$mongo_port" \
  --logpath "$mongo_log_file" \
  --logappend &
temp_pid="$!"

for _ in $(seq 1 30); do
  if mongosh --quiet --host 127.0.0.1 --port "$mongo_port" --eval "db.adminCommand({ ping: 1 }).ok" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

if ! mongosh --quiet --host 127.0.0.1 --port "$mongo_port" --eval "db.adminCommand({ ping: 1 }).ok" >/dev/null 2>&1; then
  echo "Temporary mongod server did not become ready."
  exit 1
fi

mongosh --quiet --host 127.0.0.1 --port "$mongo_port" --eval "db.getSiblingDB('admin').createUser({user:'root',pwd:'${root_password_js}',roles:[{role:'root',db:'admin'}]});" >/dev/null

if [[ "$user_name" != "root" ]]; then
  mongosh --quiet --host 127.0.0.1 --port "$mongo_port" --eval "db.getSiblingDB('admin').createUser({user:'${user_name_js}',pwd:'${service_password_js}',roles:[{role:'readWriteAnyDatabase',db:'admin'}]});" >/dev/null
fi

mongosh --quiet --host 127.0.0.1 --port "$mongo_port" --eval "db.adminCommand({shutdown: 1, force: true});" >/dev/null 2>&1 || true
wait "$temp_pid"

credentials_file="/run/hacktrap/mongodb_credentials.env"
{
  printf "MONGODB_ROOT_USER=root\n"
  printf "MONGODB_ROOT_PASSWORD=%s\n" "$root_password"
  if [[ "$user_name" != "root" ]]; then
    printf "MONGODB_SERVICE_USER=%s\n" "$user_name"
    printf "MONGODB_SERVICE_PASSWORD=%s\n" "$service_password"
  fi
} > "$credentials_file"
chmod 600 "$credentials_file"
chown mongodb:mongodb "$credentials_file"
echo "Generated random MongoDB passwords for runtime users."

exec gosu mongodb mongod \
  --dbpath "$mongo_data_dir" \
  --bind_ip_all \
  --port "$mongo_port" \
  --auth \
  --logpath "$mongo_log_file" \
  --logappend
