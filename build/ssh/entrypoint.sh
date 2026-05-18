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

if ! id "$user_name" >/dev/null 2>&1; then
  useradd -m -s /bin/bash "$user_name"
fi

generated_password="$(openssl rand -hex 24)"
echo "${user_name}:${generated_password}" | chpasswd

mkdir -p /run/hacktrap
credentials_file="/run/hacktrap/ssh_credentials.env"
printf "HACKTRAP_USER=%s\nHACKTRAP_PASSWORD=%s\n" "$user_name" "$generated_password" > "$credentials_file"
chmod 600 "$credentials_file"
echo "Generated random SSH password for user '${user_name}'."

mkdir -p /run/sshd /var/log/ssh
touch /var/log/ssh/auth.log
chmod 0644 /var/log/ssh/auth.log

ssh-keygen -A
rsyslogd

exec /usr/sbin/sshd -D -f /etc/ssh/sshd_config
