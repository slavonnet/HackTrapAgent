#!/usr/bin/env bash
set -euo pipefail

user_name="${HACKTRAP_USER:-trap}"
users_file="/opt/hacktrap/etc/l2tp/users.conf"

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

l2tp_psk="$(openssl rand -hex 24)"

mkdir -p /run/hacktrap
credentials_file="/run/hacktrap/l2tp_credentials.env"
{
  printf "L2TP_ROOT_USER=root\nL2TP_ROOT_PASSWORD=%s\n" "$root_password"
  if [[ "$user_name" != "root" ]]; then
    printf "L2TP_SERVICE_USER=%s\nL2TP_SERVICE_PASSWORD=%s\n" "$user_name" "$service_password"
  fi
  printf "L2TP_PSK=%s\n" "$l2tp_psk"
} > "$credentials_file"
chmod 600 "$credentials_file"
echo "Generated random L2TP credentials for runtime users."

mkdir -p /var/log/l2tp
touch /var/log/l2tp/l2tp.log
chmod 0644 /var/log/l2tp/l2tp.log

exec socat -u UDP-RECVFROM:1701,reuseaddr,fork SYSTEM:'/usr/local/bin/l2tp-log-packet.sh'
