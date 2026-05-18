#!/usr/bin/env bash
set -euo pipefail

user_name="${HACKTRAP_USER:-trap}"
users_file="/opt/hacktrap/etc/radius/users.conf"

if [[ -f "$users_file" ]]; then
  while IFS=: read -r cfg_user _; do
    [[ -z "${cfg_user// }" ]] && continue
    [[ "${cfg_user:0:1}" == "#" ]] && continue
    user_name="$cfg_user"
    break
  done < "$users_file"
fi

if [[ ! "$user_name" =~ ^[A-Za-z0-9_]+$ ]]; then
  echo "Invalid RADIUS runtime user: '$user_name'"
  exit 1
fi

auth_password="$(openssl rand -hex 24)"
client_secret="$(openssl rand -hex 24)"

mkdir -p /run/hacktrap /var/log/radius
credentials_file="/run/hacktrap/radius_credentials.env"
{
  printf "RADIUS_AUTH_USER=%s\n" "$user_name"
  printf "RADIUS_AUTH_PASSWORD=%s\n" "$auth_password"
  printf "RADIUS_CLIENT_SECRET=%s\n" "$client_secret"
} > "$credentials_file"
chmod 600 "$credentials_file"
echo "Generated random RADIUS honeypot credentials and client secret."

cat > /etc/freeradius/3.0/clients.d/hacktrap.conf <<EOF
client hacktrap_docker {
  ipaddr = 0.0.0.0/0
  secret = ${client_secret}
  require_message_authenticator = no
}
EOF

cat > /etc/freeradius/3.0/mods-config/files/authorize <<EOF
# Dynamic hacktrap user generated at container startup.
${user_name} Cleartext-Password := "${auth_password}"
EOF

touch /var/log/radius/radius.log
chmod 0644 /var/log/radius/radius.log

exec /usr/sbin/freeradius -f -l /var/log/radius/radius.log
