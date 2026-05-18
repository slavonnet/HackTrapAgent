#!/usr/bin/env bash
set -euo pipefail

user_name="${HACKTRAP_USER:-trap}"
users_file="/opt/hacktrap/etc/redis/users.conf"
log_file="/var/log/redis/redis.log"
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

mkdir -p /var/log/redis /run/hacktrap
touch "$log_file"
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

exec redis-server /opt/hacktrap/etc/redis/redis.conf --aclfile "$acl_file"
