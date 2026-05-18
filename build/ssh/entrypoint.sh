#!/usr/bin/env bash
set -euo pipefail

user_name="${HACKTRAP_USER:-trap}"
users_file="/opt/hacktrap/etc/ssh/users.conf"

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
credentials_file="/run/hacktrap/ssh_credentials.env"
{
  printf "SSH_ROOT_USER=root\nSSH_ROOT_PASSWORD=%s\n" "$root_password"
  if [[ "$user_name" != "root" ]]; then
    printf "SSH_SERVICE_USER=%s\nSSH_SERVICE_PASSWORD=%s\n" "$user_name" "$service_password"
  fi
} > "$credentials_file"
chmod 600 "$credentials_file"
echo "Generated random SSH passwords for runtime users."

mkdir -p /run/sshd /var/log/ssh
touch /var/log/ssh/auth.log
chmod 0644 /var/log/ssh/auth.log

ssh-keygen -A
rsyslogd

exec /usr/sbin/sshd -D -f /etc/ssh/sshd_config
