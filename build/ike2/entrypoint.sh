#!/usr/bin/env bash
set -euo pipefail

user_name="${HACKTRAP_USER:-trap}"
users_file="/opt/hacktrap/etc/ike2/users.conf"

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

ike2_psk="$(openssl rand -hex 24)"

mkdir -p /run/hacktrap
credentials_file="/run/hacktrap/ike2_credentials.env"
{
  printf "IKE2_ROOT_USER=root\nIKE2_ROOT_PASSWORD=%s\n" "$root_password"
  if [[ "$user_name" != "root" ]]; then
    printf "IKE2_SERVICE_USER=%s\nIKE2_SERVICE_PASSWORD=%s\n" "$user_name" "$service_password"
  fi
  printf "IKE2_PSK=%s\n" "$ike2_psk"
} > "$credentials_file"
chmod 600 "$credentials_file"
echo "Generated random IKEv2 credentials for runtime users."

mkdir -p /var/log/ike2
touch /var/log/ike2/ike2.log
chmod 0644 /var/log/ike2/ike2.log

socat -u UDP-RECVFROM:500,reuseaddr,fork SYSTEM:'/usr/local/bin/ike2-log-packet.sh 500' &
pid_500="$!"
socat -u UDP-RECVFROM:4500,reuseaddr,fork SYSTEM:'/usr/local/bin/ike2-log-packet.sh 4500' &
pid_4500="$!"

cleanup() {
  kill "$pid_500" "$pid_4500" >/dev/null 2>&1 || true
}

trap cleanup TERM INT

set +e
wait -n "$pid_500" "$pid_4500"
exit_code="$?"
set -e

cleanup
wait "$pid_500" "$pid_4500" >/dev/null 2>&1 || true
exit "$exit_code"
