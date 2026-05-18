#!/usr/bin/env bash
set -euo pipefail

user_name="${HACKTRAP_USER:-trap}"
users_file="/opt/hacktrap/etc/snmp/users.conf"

if [[ -f "$users_file" ]]; then
  while IFS=: read -r cfg_user _; do
    [[ -z "${cfg_user// }" ]] && continue
    [[ "${cfg_user:0:1}" == "#" ]] && continue
    user_name="$cfg_user"
    break
  done < "$users_file"
fi

if [[ ! "$user_name" =~ ^[A-Za-z0-9_][A-Za-z0-9_.-]*$ ]]; then
  echo "Invalid SNMP runtime user: '$user_name'"
  exit 1
fi

snmp_community="$(openssl rand -hex 16)"
v3_auth_password="$(openssl rand -hex 24)"
v3_priv_password="$(openssl rand -hex 24)"

mkdir -p /run/hacktrap /var/log/snmp /var/lib/snmp /etc/snmp

credentials_file="/run/hacktrap/snmp_credentials.env"
{
  printf "SNMP_V2C_COMMUNITY=%s\n" "$snmp_community"
  printf "SNMP_V3_USER=%s\n" "$user_name"
  printf "SNMP_V3_AUTH_PASSWORD=%s\n" "$v3_auth_password"
  printf "SNMP_V3_PRIV_PASSWORD=%s\n" "$v3_priv_password"
} > "$credentials_file"
chmod 600 "$credentials_file"
echo "Generated random SNMP community and SNMPv3 credentials."

touch /var/log/snmp/snmpd.log
chmod 0644 /var/log/snmp/snmpd.log

cat > /var/lib/snmp/snmpd.conf <<EOF_SNMP_USER
createUser ${user_name} SHA "${v3_auth_password}" AES "${v3_priv_password}"
EOF_SNMP_USER
chmod 600 /var/lib/snmp/snmpd.conf

cat > /etc/snmp/snmpd.conf <<EOF_SNMP_MAIN
agentaddress udp:161
sysLocation Unknown
sysContact root
sysName hacktrap-snmp
master agentx

view readonly included .1 80
rocommunity ${snmp_community} default -V readonly
rouser ${user_name} authPriv -V readonly
authtrapenable 1
EOF_SNMP_MAIN

rsyslogd

exec /usr/sbin/snmpd -f -p /run/snmpd.pid -c /etc/snmp/snmpd.conf
