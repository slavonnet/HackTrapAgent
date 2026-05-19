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
users_file="/opt/hacktrap/etc/imap/users.conf"
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
  echo "Invalid IMAP runtime user: '$user_name'"
  exit 1
fi

root_password="$(openssl rand -hex 24)"
service_password=""
if [[ "$user_name" != "root" ]]; then
  service_password="$(openssl rand -hex 24)"
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
touch /var/log/imap/dovecot.log
chmod 0644 /var/log/imap/dovecot.log

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
