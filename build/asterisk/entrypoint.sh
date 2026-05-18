#!/usr/bin/env bash
set -euo pipefail

user_name="${HACKTRAP_USER:-trap}"
users_file="/opt/hacktrap/etc/asterisk/users.conf"

if [[ -f "$users_file" ]]; then
  while IFS=: read -r cfg_user _; do
    [[ -z "${cfg_user// }" ]] && continue
    [[ "${cfg_user:0:1}" == "#" ]] && continue
    user_name="$cfg_user"
    break
  done < "$users_file"
fi

if [[ ! "$user_name" =~ ^[A-Za-z0-9_]+$ ]]; then
  echo "Invalid Asterisk runtime user: '$user_name'"
  exit 1
fi

service_password="$(openssl rand -hex 24)"
credentials_file="/run/hacktrap/asterisk_credentials.env"

mkdir -p /run/hacktrap /etc/asterisk /var/log/asterisk /var/run/asterisk

{
  printf "ASTERISK_SERVICE_USER=%s\n" "$user_name"
  printf "ASTERISK_SERVICE_PASSWORD=%s\n" "$service_password"
} > "$credentials_file"
chmod 600 "$credentials_file"
echo "Generated random Asterisk runtime password."

cp -f /opt/hacktrap/etc/asterisk/logger.conf /etc/asterisk/logger.conf
cp -f /opt/hacktrap/etc/asterisk/extensions.conf /etc/asterisk/extensions.conf

for templated_conf in pjsip iax manager http ari; do
  sed \
    -e "s/__ASTERISK_USER__/${user_name}/g" \
    -e "s/__ASTERISK_PASSWORD__/${service_password}/g" \
    "/opt/hacktrap/etc/asterisk/${templated_conf}.conf.template" \
    > "/etc/asterisk/${templated_conf}.conf"
done

touch /var/log/asterisk/messages /var/log/asterisk/security
chmod 0644 /var/log/asterisk/messages /var/log/asterisk/security

exec /usr/sbin/asterisk -f -vvv
