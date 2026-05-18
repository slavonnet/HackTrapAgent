#!/usr/bin/env bash
set -euo pipefail

user_name="${HACKTRAP_USER:-trap}"
users_file="/opt/hacktrap/etc/ad/users.conf"

if [[ -f "$users_file" ]]; then
  while IFS=: read -r cfg_user _; do
    [[ -z "${cfg_user// }" ]] && continue
    [[ "${cfg_user:0:1}" == "#" ]] && continue
    user_name="$cfg_user"
    break
  done < "$users_file"
fi

if [[ ! "$user_name" =~ ^[A-Za-z0-9_]+$ ]]; then
  echo "Invalid AD runtime user: '$user_name'"
  exit 1
fi

if ! id "$user_name" >/dev/null 2>&1; then
  useradd -M -s /usr/sbin/nologin "$user_name"
fi

root_password="$(openssl rand -hex 24)"
service_password="$(openssl rand -hex 24)"

echo "root:${root_password}" | chpasswd
echo "${user_name}:${service_password}" | chpasswd

if pdbedit -Lw -u root >/dev/null 2>&1; then
  smbpasswd -x root >/dev/null 2>&1 || true
fi
if pdbedit -Lw -u "$user_name" >/dev/null 2>&1; then
  smbpasswd -x "$user_name" >/dev/null 2>&1 || true
fi

printf "%s\n%s\n" "$root_password" "$root_password" | smbpasswd -s -a root >/dev/null
printf "%s\n%s\n" "$service_password" "$service_password" | smbpasswd -s -a "$user_name" >/dev/null

mkdir -p /run/hacktrap /var/log/ad /run/samba /srv/ad/share
chown -R "${user_name}:${user_name}" /srv/ad/share
touch /var/log/ad/log.smbd
chmod 0644 /var/log/ad/log.smbd

credentials_file="/run/hacktrap/ad_credentials.env"
{
  printf "AD_ROOT_USER=root\nAD_ROOT_PASSWORD=%s\n" "$root_password"
  printf "AD_SERVICE_USER=%s\nAD_SERVICE_PASSWORD=%s\n" "$user_name" "$service_password"
} > "$credentials_file"
chmod 600 "$credentials_file"
echo "Generated random AD/Samba passwords for runtime users."

exec /usr/sbin/smbd --foreground --no-process-group --configfile=/etc/samba/smb.conf
