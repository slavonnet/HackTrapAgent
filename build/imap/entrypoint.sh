#!/usr/bin/env bash
set -euo pipefail

user_name="${HACKTRAP_USER:-trap}"
users_file="/opt/hacktrap/etc/imap/users.conf"

if [[ -f "$users_file" ]]; then
  while IFS=: read -r cfg_user _; do
    [[ -z "${cfg_user// }" ]] && continue
    [[ "${cfg_user:0:1}" == "#" ]] && continue
    user_name="$cfg_user"
    break
  done < "$users_file"
fi

root_password="$(openssl rand -hex 24)"
echo "root:${root_password}" | chpasswd

service_password=""
if [[ "$user_name" != "root" ]]; then
  if ! id "$user_name" >/dev/null 2>&1; then
    useradd -m -s /bin/bash "$user_name"
  fi
  service_password="$(openssl rand -hex 24)"
  echo "${user_name}:${service_password}" | chpasswd
fi

login_password="$root_password"
if [[ "$user_name" != "root" ]]; then
  login_password="$service_password"
fi

mkdir -p /run/hacktrap
credentials_file="/run/hacktrap/imap_credentials.env"
{
  printf "IMAP_ROOT_USER=root\nIMAP_ROOT_PASSWORD=%s\n" "$root_password"
  if [[ "$user_name" != "root" ]]; then
    printf "IMAP_SERVICE_USER=%s\nIMAP_SERVICE_PASSWORD=%s\n" "$user_name" "$service_password"
  fi
} > "$credentials_file"
chmod 600 "$credentials_file"
echo "Generated random IMAP passwords for runtime users."

mkdir -p /var/log/imap
touch /var/log/imap/imap-auth.log
chmod 0644 /var/log/imap/imap-auth.log

export IMAP_RUNTIME_USER="$user_name"
export IMAP_RUNTIME_PASSWORD="$login_password"

exec python3 /usr/local/bin/imap_server.py --host 0.0.0.0 --port 143 --log-file /var/log/imap/imap-auth.log
