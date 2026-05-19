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
users_file="/opt/hacktrap/etc/smb/users.conf"

if [[ -f "$users_file" ]]; then
  while IFS=: read -r cfg_user _; do
    [[ -z "${cfg_user// }" ]] && continue
    [[ "${cfg_user:0:1}" == "#" ]] && continue
    user_name="$cfg_user"
    break
  done < "$users_file"
fi

if [[ ! "$user_name" =~ ^[A-Za-z0-9_]+$ ]]; then
  echo "Invalid SMB runtime user: '$user_name'"
  exit 1
fi

if ! getent group smbusers >/dev/null 2>&1; then
  groupadd smbusers
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
  usermod -a -G smbusers "$user_name"
else
  usermod -a -G smbusers root
fi

printf '%s\n%s\n' "$root_password" "$root_password" | smbpasswd -a -s root >/dev/null
if [[ "$user_name" != "root" ]]; then
  printf '%s\n%s\n' "$service_password" "$service_password" | smbpasswd -a -s "$user_name" >/dev/null
fi

mkdir -p /srv/smb/trapshare /var/log/smb /run/samba /run/hacktrap
touch /var/log/smb/log.smbd
chmod 0644 /var/log/smb/log.smbd

if [[ "$user_name" != "root" ]]; then
  chown -R "${user_name}:smbusers" /srv/smb/trapshare
else
  chown -R "root:smbusers" /srv/smb/trapshare
fi
chmod 0770 /srv/smb/trapshare

credentials_file="/run/hacktrap/smb_credentials.env"
{
  printf "SMB_ROOT_USER=root\nSMB_ROOT_PASSWORD=%s\n" "$root_password"
  if [[ "$user_name" != "root" ]]; then
    printf "SMB_SERVICE_USER=%s\nSMB_SERVICE_PASSWORD=%s\n" "$user_name" "$service_password"
  fi
} > "$credentials_file"
chmod 600 "$credentials_file"
echo "Generated random SMB passwords for runtime users."

testparm -s >/dev/null

exec /usr/sbin/smbd --foreground --no-process-group --configfile=/etc/samba/smb.conf
