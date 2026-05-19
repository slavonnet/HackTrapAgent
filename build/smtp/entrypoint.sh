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
users_file="/opt/hacktrap/etc/smtp/users.conf"

if [[ -f "$users_file" ]]; then
  while IFS=: read -r cfg_user _; do
    [[ -z "${cfg_user// }" ]] && continue
    [[ "${cfg_user:0:1}" == "#" ]] && continue
    user_name="$cfg_user"
    break
  done < "$users_file"
fi

if [[ ! "$user_name" =~ ^[A-Za-z0-9_]+$ ]]; then
  echo "Invalid SMTP runtime user: '$user_name'"
  exit 1
fi

root_password="$(openssl rand -hex 24)"
service_password=""
if [[ "$user_name" != "root" ]]; then
  service_password="$(openssl rand -hex 24)"
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
touch /var/log/smtp/mail.log
chmod 0644 /var/log/smtp/mail.log

rm -f /etc/sasldb2
printf '%s\n' "$root_password" | saslpasswd2 -p -c root
if [[ "$user_name" != "root" ]]; then
  printf '%s\n' "$service_password" | saslpasswd2 -p -c "$user_name"
fi
chmod 0644 /etc/sasldb2

exec /usr/sbin/postfix start-fg
