#!/usr/bin/env bash
set -euo pipefail

user_name="${HACKTRAP_USER:-trap}"
users_file="/opt/hacktrap/etc/rdp/users.conf"

if [[ -f "$users_file" ]]; then
  while IFS=: read -r cfg_user _; do
    [[ -z "${cfg_user// }" ]] && continue
    [[ "${cfg_user:0:1}" == "#" ]] && continue
    user_name="$cfg_user"
    break
  done < "$users_file"
fi

if [[ ! "$user_name" =~ ^[A-Za-z0-9_]+$ ]]; then
  echo "Invalid RDP runtime user: '$user_name'"
  exit 1
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

credentials_file="/run/hacktrap/rdp_credentials.env"
{
  printf "RDP_ROOT_USER=root\nRDP_ROOT_PASSWORD=%s\n" "$root_password"
  if [[ "$user_name" != "root" ]]; then
    printf "RDP_SERVICE_USER=%s\nRDP_SERVICE_PASSWORD=%s\n" "$user_name" "$service_password"
  fi
} > "$credentials_file"
chmod 600 "$credentials_file"
echo "Generated random RDP passwords for runtime users."

mkdir -p /var/log/rdp /var/run/xrdp
touch /var/log/rdp/xrdp.log /var/log/rdp/xrdp-sesman.log
chmod 0644 /var/log/rdp/xrdp.log /var/log/rdp/xrdp-sesman.log
chown -R xrdp:xrdp /var/log/rdp /var/run/xrdp

sed -i 's|^[[:space:]]*LogFile=.*|LogFile=/var/log/rdp/xrdp.log|' /etc/xrdp/xrdp.ini
sed -i 's|^[[:space:]]*EnableSyslog=.*|EnableSyslog=false|' /etc/xrdp/xrdp.ini
sed -i 's|^[[:space:]]*LogLevel=.*|LogLevel=INFO|' /etc/xrdp/xrdp.ini

sed -i 's|^[[:space:]]*LogFile=.*|LogFile=/var/log/rdp/xrdp-sesman.log|' /etc/xrdp/sesman.ini
sed -i 's|^[[:space:]]*EnableSyslog=.*|EnableSyslog=false|' /etc/xrdp/sesman.ini
sed -i 's|^[[:space:]]*LogLevel=.*|LogLevel=INFO|' /etc/xrdp/sesman.ini

/usr/sbin/xrdp-sesman --nodaemon &
sesman_pid=$!
/usr/sbin/xrdp --nodaemon &
xrdp_pid=$!

wait -n "$sesman_pid" "$xrdp_pid"
exit_code=$?

kill "$sesman_pid" "$xrdp_pid" >/dev/null 2>&1 || true
wait "$sesman_pid" "$xrdp_pid" >/dev/null 2>&1 || true

exit "$exit_code"
