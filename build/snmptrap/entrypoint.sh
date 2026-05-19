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
doNotLogTraps no
createUser ${user_name} SHA "${v3_auth_password}" AES "${v3_priv_password}"
authcommunity log,execute,net ${trap_community}
authcommunity log,execute,net public
authcommunity log,execute,net private
authuser log,execute,net ${user_name}
authtrapenable 1
EOF_SNMPTRAP_MAIN
chmod 600 /etc/snmp/snmptrapd.conf

cat > /etc/snmp/snmp.conf <<EOF_SNMPTRAP_CLIENT
mibs :
EOF_SNMPTRAP_CLIENT

last_peer_ip=""
/usr/sbin/snmptrapd -f -C -Lo -On -F "src=%b|sec=%P|vars=%v\n" -p /run/snmptrapd.pid -c /etc/snmp/snmptrapd.conf 2>&1 | while IFS= read -r line; do
  timestamp="$(date "+%Y-%m-%d %H:%M:%S")"
  printf "%s snmptrapd: %s\n" "$timestamp" "$line" >> /var/log/snmptrap/snmptrapd.log

  if [[ "$line" =~ src=UDP:\ \[([0-9A-Fa-f:.]+)\]:[0-9]+-\>\[[0-9A-Fa-f:.]+\]:[0-9]+\|sec=([^|]+)\| ]]; then
    last_peer_ip="${BASH_REMATCH[1]}"
    security_info="${BASH_REMATCH[2]}"
    is_authorized=0

    if [[ "$security_info" == *"$trap_community"* ]]; then
      is_authorized=1
    fi

    if [[ "$security_info" == *"$user_name"* ]]; then
      is_authorized=1
    fi

    if [[ "$line" =~ ([Aa]uthentication\ failed|[Uu]nknown\ user|[Uu]nknown\ engine|[Nn]ot\ in\ time\ window|[Ww]rong\ digest|[Dd]ecryption\ error) ]]; then
      is_authorized=0
    fi

    if [[ "$is_authorized" -eq 0 ]]; then
      printf "%s snmptrapd-auth: SNMPTRAP_AUTH_FAILED from %s sec=%s\n" "$timestamp" "$last_peer_ip" "$security_info" >> /var/log/snmptrap/snmptrapd.log
    fi
  fi
done
