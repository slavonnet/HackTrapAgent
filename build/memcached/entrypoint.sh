#!/usr/bin/env bash
set -euo pipefail

user_name="${HACKTRAP_USER:-trap}"
users_file="/opt/hacktrap/etc/memcached/users.conf"
backend_host="127.0.0.1"
backend_port="11212"
listen_host="0.0.0.0"
listen_port="11211"
log_file="/var/log/memcached/memcached.log"

if [[ -f "$users_file" ]]; then
  while IFS=: read -r cfg_user _; do
    [[ -z "${cfg_user// }" ]] && continue
    [[ "${cfg_user:0:1}" == "#" ]] && continue
    user_name="$cfg_user"
    break
  done < "$users_file"
fi

if [[ ! "$user_name" =~ ^[A-Za-z0-9_]+$ ]]; then
  echo "Invalid memcached runtime user: '$user_name'"
  exit 1
fi

auth_password="$(openssl rand -hex 24)"

mkdir -p /run/hacktrap /var/log/memcached
touch "$log_file"
chmod 0644 "$log_file"

credentials_file="/run/hacktrap/memcached_credentials.env"
{
  printf "MEMCACHED_AUTH_USER=%s\n" "$user_name"
  printf "MEMCACHED_AUTH_PASSWORD=%s\n" "$auth_password"
} > "$credentials_file"
chmod 600 "$credentials_file"
echo "Generated random memcached proxy credentials."

memcached -u memcache -m 64 -l "$backend_host" -p "$backend_port" >/dev/null 2>&1 &
backend_pid="$!"
trap 'kill "$backend_pid" >/dev/null 2>&1 || true' EXIT

for _ in $(seq 1 30); do
  if python3 -c "import socket; s=socket.create_connection(('${backend_host}', ${backend_port}), 1); s.close()" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

if ! python3 -c "import socket; s=socket.create_connection(('${backend_host}', ${backend_port}), 1); s.close()" >/dev/null 2>&1; then
  echo "Memcached backend did not become ready."
  exit 1
fi

exec python3 /usr/local/bin/memcached-auth-proxy.py \
  --listen-host "$listen_host" \
  --listen-port "$listen_port" \
  --backend-host "$backend_host" \
  --backend-port "$backend_port" \
  --auth-user "$user_name" \
  --auth-password "$auth_password" \
  --log-file "$log_file"
