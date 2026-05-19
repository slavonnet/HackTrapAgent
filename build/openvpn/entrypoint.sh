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
users_file="/opt/hacktrap/etc/openvpn/users.conf"

if [[ -f "$users_file" ]]; then
  while IFS=':' read -r cfg_user _; do
    [[ -z "${cfg_user// }" ]] && continue
    [[ "${cfg_user:0:1}" == "#" ]] && continue
    user_name="$cfg_user"
    break
  done < "$users_file"
fi

auth_password="$(openssl rand -hex 24)"

mkdir -p /run/hacktrap /var/log/openvpn
credentials_file="/run/hacktrap/openvpn_credentials.env"
{
  printf "OPENVPN_AUTH_USER=%s\n" "$user_name"
  printf "OPENVPN_AUTH_PASSWORD=%s\n" "$auth_password"
} > "$credentials_file"
chmod 600 "$credentials_file"
echo "Generated random OpenVPN honeypot credentials."

touch /var/log/openvpn/openvpn.log
chmod 0644 /var/log/openvpn/openvpn.log

export OPENVPN_HONEYPOT_USER="$user_name"

exec socat -T5 UDP-LISTEN:1194,reuseaddr,fork EXEC:/usr/local/bin/openvpn-log-attempt.sh
