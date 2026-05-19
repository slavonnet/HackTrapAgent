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
users_file="/opt/hacktrap/etc/pop3/users.conf"
passwd_file="/run/hacktrap/dovecot.passwd"

if [[ -f "$users_file" ]]; then
  while IFS=: read -r cfg_user _; do
    [[ -z "${cfg_user// }" ]] && continue
    [[ "${cfg_user:0:1}" == "#" ]] && continue
    user_name="$cfg_user"
    break
  done < "$users_file"
fi

if [[ ! "$user_name" =~ ^[A-Za-z0-9_]+$ ]]; then
  echo "Invalid POP3 runtime user: '$user_name'"
  exit 1
fi

root_password="$(openssl rand -hex 24)"
service_password=""
if [[ "$user_name" != "root" ]]; then
  service_password="$(openssl rand -hex 24)"
fi

mkdir -p /run/hacktrap
credentials_file="/run/hacktrap/pop3_credentials.env"
{
  printf "POP3_ROOT_USER=root\nPOP3_ROOT_PASSWORD=%s\n" "$root_password"
  if [[ "$user_name" != "root" ]]; then
    printf "POP3_SERVICE_USER=%s\nPOP3_SERVICE_PASSWORD=%s\n" "$user_name" "$service_password"
  fi
} > "$credentials_file"
chmod 600 "$credentials_file"
echo "Generated random POP3 passwords for runtime users."

mkdir -p /var/log/pop3
touch /var/log/pop3/dovecot.log
chmod 0644 /var/log/pop3/dovecot.log

mkdir -p /var/mail/root/Maildir
chown -R 0:0 /var/mail/root || true

{
  printf "root:{PLAIN}%s:0:0::/var/mail/root::\n" "$root_password"
  if [[ "$user_name" != "root" ]]; then
    mkdir -p "/var/mail/${user_name}/Maildir"
    chown -R 5000:5000 "/var/mail/${user_name}" || true
    printf "%s:{PLAIN}%s:5000:5000::/var/mail/%s::\n" "$user_name" "$service_password" "$user_name"
  fi
} > "$passwd_file"
chown root:dovecot "$passwd_file" || true
chmod 0640 "$passwd_file"

exec /usr/sbin/dovecot -F -c /etc/dovecot/dovecot.conf
