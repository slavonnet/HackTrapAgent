#!/usr/bin/env bash
set -euo pipefail

user_name="${HACKTRAP_USER:-trap}"
users_file="/opt/hacktrap/etc/smtp/users.conf"

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
credentials_file="/run/hacktrap/smtp_credentials.env"
{
  printf "SMTP_ROOT_USER=root\nSMTP_ROOT_PASSWORD=%s\n" "$root_password"
  if [[ "$user_name" != "root" ]]; then
    printf "SMTP_SERVICE_USER=%s\nSMTP_SERVICE_PASSWORD=%s\n" "$user_name" "$service_password"
  fi
} > "$credentials_file"
chmod 600 "$credentials_file"
echo "Generated random SMTP passwords for runtime users."

mkdir -p /var/log/smtp
touch /var/log/smtp/smtp-auth.log
chmod 0644 /var/log/smtp/smtp-auth.log

export SMTP_RUNTIME_USER="$user_name"
export SMTP_RUNTIME_PASSWORD="$login_password"

exec python3 /usr/local/bin/smtp_server.py --host 0.0.0.0 --port 25 --log-file /var/log/smtp/smtp-auth.log
