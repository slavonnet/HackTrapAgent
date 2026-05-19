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
users_file="/opt/hacktrap/etc/ftp/users.conf"

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

mkdir -p /run/hacktrap
credentials_file="/run/hacktrap/ftp_credentials.env"
{
  printf "FTP_ROOT_USER=root\nFTP_ROOT_PASSWORD=%s\n" "$root_password"
  if [[ "$user_name" != "root" ]]; then
    printf "FTP_SERVICE_USER=%s\nFTP_SERVICE_PASSWORD=%s\n" "$user_name" "$service_password"
  fi
} > "$credentials_file"
chmod 600 "$credentials_file"
echo "Generated random FTP passwords for runtime users."

mkdir -p /var/log/ftp /run/vsftpd/empty
touch /var/log/ftp/vsftpd.log
chmod 0644 /var/log/ftp/vsftpd.log

exec /usr/sbin/vsftpd /etc/vsftpd.conf
