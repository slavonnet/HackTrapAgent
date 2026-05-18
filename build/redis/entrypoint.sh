#!/usr/bin/env bash
set -euo pipefail

user_name="${HACKTRAP_USER:-trap}"
users_file="/opt/hacktrap/etc/redis/users.conf"
log_file="/var/log/redis/redis.log"
auth_log_file="/var/log/redis/redis-auth.log"
credentials_file="/run/hacktrap/redis_credentials.env"
acl_file="/run/hacktrap/users.acl"

if [[ -f "$users_file" ]]; then
  while IFS= read -r cfg_user; do
    cfg_user="${cfg_user%%#*}"
    cfg_user="$(echo "$cfg_user" | xargs)"
    [[ -z "$cfg_user" ]] && continue
    user_name="$cfg_user"
    break
  done < "$users_file"
fi

if [[ ! "$user_name" =~ ^[A-Za-z0-9_]+$ ]]; then
  echo "Invalid redis runtime user: '$user_name'"
  exit 1
fi

password="$(openssl rand -hex 24)"
service_ip="$(hostname -i | awk '{print $1}')"

mkdir -p /var/log/redis /run/hacktrap
touch "$log_file"
touch "$auth_log_file"
chown -R redis:redis /var/log/redis

if [[ "$user_name" == "default" ]]; then
  {
    printf "user default on >%s ~* +@all\n" "$password"
  } > "$acl_file"
else
  {
    echo "user default off"
    printf "user %s on >%s ~* +@all\n" "$user_name" "$password"
  } > "$acl_file"
fi
chown redis:redis "$acl_file"
chmod 600 "$acl_file"

{
  printf "REDIS_SERVICE_USER=%s\n" "$user_name"
  printf "REDIS_SERVICE_PASSWORD=%s\n" "$password"
} > "$credentials_file"
chmod 600 "$credentials_file"
echo "Generated random Redis ACL password for runtime user."

extract_addr() {
  printf "%s\n" "$1" | sed -n 's/.*[[:space:]]addr=\([^ ]*\).*/\1/p'
}

append_acl_events_to_log() {
  local acl_raw="$1"
  local current_key=""
  local reason=""
  local username=""
  local object=""

  while IFS= read -r line; do
    case "$line" in
      reason|context|object|username|age-seconds|client-info|count)
        current_key="$line"
        ;;
      *)
        case "$current_key" in
          reason)
            reason="$line"
            ;;
          username)
            username="$line"
            ;;
          object)
            object="$line"
            ;;
          client-info)
            addr="$(extract_addr "$line")"
            if [[ -n "$addr" && "$addr" != "${service_ip}:"* && "$addr" != "127.0.0.1:"* ]]; then
              printf "%s redis-acl reason=%s username=%s object=%s addr=%s\n" \
                "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
                "${reason:-unknown}" \
                "${username:-unknown}" \
                "${object:-unknown}" \
                "$addr" >> "$auth_log_file"
            fi
            reason=""
            username=""
            object=""
            ;;
        esac
        current_key=""
        ;;
    esac
  done <<< "$acl_raw"
}

redis-server /opt/hacktrap/etc/redis/redis.conf --aclfile "$acl_file" &
redis_pid="$!"

for _ in $(seq 1 30); do
  if redis-cli --no-auth-warning --user "$user_name" --pass "$password" -h 127.0.0.1 -p 6379 PING 2>/dev/null | grep -q "PONG"; then
    break
  fi
  sleep 1
done

if ! redis-cli --no-auth-warning --user "$user_name" --pass "$password" -h 127.0.0.1 -p 6379 PING 2>/dev/null | grep -q "PONG"; then
  echo "Redis service did not become ready."
  exit 1
fi

redis-cli --no-auth-warning --user "$user_name" --pass "$password" -h 127.0.0.1 -p 6379 ACL LOG RESET >/dev/null 2>&1 || true

while kill -0 "$redis_pid" >/dev/null 2>&1; do
  acl_events="$(redis-cli --no-auth-warning --user "$user_name" --pass "$password" -h 127.0.0.1 -p 6379 --raw ACL LOG 128 2>/dev/null || true)"
  if [[ -n "$acl_events" ]]; then
    append_acl_events_to_log "$acl_events"
    redis-cli --no-auth-warning --user "$user_name" --pass "$password" -h 127.0.0.1 -p 6379 ACL LOG RESET >/dev/null 2>&1 || true
  fi
  sleep 1
done &
acl_log_pid="$!"

wait "$redis_pid"
wait "$acl_log_pid" >/dev/null 2>&1 || true
