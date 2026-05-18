#!/usr/bin/env bash
set -euo pipefail

user_name="${HACKTRAP_USER:-trap}"
user_password="${HACKTRAP_PASSWORD:-trap123}"
users_file="/opt/hacktrap/local/ssh/users.conf"

if [[ -f "$users_file" ]]; then
  while IFS=: read -r cfg_user cfg_password; do
    [[ -z "${cfg_user// }" ]] && continue
    [[ "${cfg_user:0:1}" == "#" ]] && continue

    user_name="$cfg_user"
    if [[ -n "${cfg_password:-}" ]]; then
      user_password="$cfg_password"
    fi
    break
  done < "$users_file"
fi

if ! id "$user_name" >/dev/null 2>&1; then
  useradd -m -s /bin/bash "$user_name"
fi

echo "${user_name}:${user_password}" | chpasswd

mkdir -p /run/sshd /var/log/ssh
touch /var/log/ssh/auth.log
chmod 0644 /var/log/ssh/auth.log

ssh-keygen -A

rsyslogd

exec /usr/sbin/sshd -D -f /etc/ssh/sshd_config
