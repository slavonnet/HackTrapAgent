#!/usr/bin/env bash
set -euo pipefail

user_name="${HACKTRAP_USER:-trap}"
users_file="/opt/hacktrap/etc/elasticsearch/users.conf"
credentials_file="/run/hacktrap/elasticsearch_credentials.env"

if [[ -f "$users_file" ]]; then
  while IFS=: read -r cfg_user _; do
    [[ -z "${cfg_user// }" ]] && continue
    [[ "${cfg_user:0:1}" == "#" ]] && continue
    user_name="$cfg_user"
    break
  done < "$users_file"
fi

if [[ ! "$user_name" =~ ^[A-Za-z0-9_.-]+$ ]]; then
  echo "Invalid Elasticsearch runtime user: '$user_name'"
  exit 1
fi

user_password="$(openssl rand -hex 24)"

mkdir -p /run/hacktrap /var/log/elasticsearch
touch /var/log/elasticsearch/elasticsearch.log
chmod 0644 /var/log/elasticsearch/elasticsearch.log

{
  printf "ELASTICSEARCH_SERVICE_USER=%s\n" "$user_name"
  printf "ELASTICSEARCH_SERVICE_PASSWORD=%s\n" "$user_password"
} > "$credentials_file"
chmod 600 "$credentials_file"
echo "Generated random Elasticsearch password for runtime user."

export ELASTICSEARCH_HONEYPOT_USER="$user_name"
export ELASTICSEARCH_HONEYPOT_PASSWORD="$user_password"

exec python3 /opt/hacktrap/elasticsearch/server.py
