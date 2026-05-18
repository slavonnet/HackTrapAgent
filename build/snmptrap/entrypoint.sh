#!/usr/bin/env bash
set -euo pipefail

user_name="${HACKTRAP_USER:-trap}"
users_file="/opt/hacktrap/etc/snmptrap/users.conf"

if [[ -f "$users_file" ]]; then
  while IFS=: read -r cfg_user _; do
    [[ -z "${cfg_user// }" ]] && continue
    [[ "${cfg_user:0:1}" == "#" ]] && continue
    user_name="$cfg_user"
    break
  done < "$users_file"
fi

if [[ ! "$user_name" =~ ^[A-Za-z0-9_][A-Za-z0-9_.-]*$ ]]; then
  echo "Invalid SNMP trap runtime user: '$user_name'"
  exit 1
fi

trap_community="$(openssl rand -hex 16)"
v3_auth_password="$(openssl rand -hex 24)"
v3_priv_password="$(openssl rand -hex 24)"

mkdir -p /run/hacktrap /var/log/snmptrap /var/lib/snmp /etc/snmp

credentials_file="/run/hacktrap/snmptrap_credentials.env"
{
  printf "SNMPTRAP_V2C_COMMUNITY=%s\n" "$trap_community"
  printf "SNMPTRAP_V3_USER=%s\n" "$user_name"
  printf "SNMPTRAP_V3_AUTH_PASSWORD=%s\n" "$v3_auth_password"
  printf "SNMPTRAP_V3_PRIV_PASSWORD=%s\n" "$v3_priv_password"
} > "$credentials_file"
chmod 600 "$credentials_file"
echo "Generated random SNMP trap community and SNMPv3 credentials."

touch /var/log/snmptrap/snmptrapd.log
chmod 0644 /var/log/snmptrap/snmptrapd.log

cat > /etc/snmp/snmptrapd.conf <<EOF_SNMPTRAP_MAIN
disableAuthorization no
authCommunity log,execute,net ${trap_community}
createUser ${user_name} SHA "${v3_auth_password}" AES "${v3_priv_password}"
authUser log,execute,net ${user_name}
EOF_SNMPTRAP_MAIN
chmod 600 /etc/snmp/snmptrapd.conf

rsyslogd

exec /usr/sbin/snmptrapd -f -p /run/snmptrapd.pid -c /etc/snmp/snmptrapd.conf
