#!/usr/bin/env bash
set -euo pipefail

service_name="snmp"
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# shellcheck source=tests/common/compose_test_lib.sh
source "${project_root}/tests/common/compose_test_lib.sh"

load_service_config
set_compose_project_name "$service_name"

trap cleanup_compose EXIT

init_docker_cmd
init_host_iptables_bins

compose --profile test up -d --build "$service_name" fail2ban attacker

wait_for_exec_success "$service_name" "pgrep -x snmpd"
wait_for_exec_success "fail2ban" "fail2ban-client ping"

attacker_ip="$(get_attacker_ip)"

if [[ -z "$attacker_ip" ]]; then
  echo "Cannot determine attacker IP"
  exit 1
fi

snmp_community="$(compose exec -T "$service_name" sh -lc '. /run/hacktrap/snmp_credentials.env && printf "%s" "$SNMP_V2C_COMMUNITY"')"
snmp_v3_user="$(compose exec -T "$service_name" sh -lc '. /run/hacktrap/snmp_credentials.env && printf "%s" "$SNMP_V3_USER"')"
snmp_v3_auth_password="$(compose exec -T "$service_name" sh -lc '. /run/hacktrap/snmp_credentials.env && printf "%s" "$SNMP_V3_AUTH_PASSWORD"')"
snmp_v3_priv_password="$(compose exec -T "$service_name" sh -lc '. /run/hacktrap/snmp_credentials.env && printf "%s" "$SNMP_V3_PRIV_PASSWORD"')"

if [[ -z "$snmp_community" || -z "$snmp_v3_user" || -z "$snmp_v3_auth_password" || -z "$snmp_v3_priv_password" ]]; then
  echo "SNMP runtime credentials are missing"
  exit 1
fi

if compose exec -T attacker sh -lc 'snmpget -v2c -c public -t 1 -r 0 -Oqv snmp .1.3.6.1.2.1.1.1.0 >/dev/null 2>&1'; then
  echo "SNMP unexpectedly answered to community 'public'"
  exit 1
fi

if compose exec -T attacker sh -lc 'snmpget -v2c -c private -t 1 -r 0 -Oqv snmp .1.3.6.1.2.1.1.1.0 >/dev/null 2>&1'; then
  echo "SNMP unexpectedly answered to community 'private'"
  exit 1
fi

if ! compose exec -T -e SNMP_COMMUNITY="$snmp_community" attacker sh -lc 'snmpget -v2c -c "$SNMP_COMMUNITY" -t 1 -r 0 -Oqv snmp .1.3.6.1.2.1.1.1.0 >/dev/null'; then
  echo "SNMP did not answer with generated random community"
  exit 1
fi

if ! compose exec -T \
  -e SNMP_V3_USER="$snmp_v3_user" \
  -e SNMP_V3_AUTH_PASSWORD="$snmp_v3_auth_password" \
  -e SNMP_V3_PRIV_PASSWORD="$snmp_v3_priv_password" \
  attacker sh -lc 'snmpget -v3 -l authPriv -u "$SNMP_V3_USER" -a SHA -A "$SNMP_V3_AUTH_PASSWORD" -x AES -X "$SNMP_V3_PRIV_PASSWORD" -t 1 -r 0 -Oqv snmp .1.3.6.1.2.1.1.1.0 >/dev/null'; then
  echo "SNMPv3 authentication with generated credentials failed"
  exit 1
fi

if compose exec -T \
  -e SNMP_V3_USER="$snmp_v3_user" \
  -e SNMP_V3_PRIV_PASSWORD="$snmp_v3_priv_password" \
  attacker sh -lc 'snmpget -v3 -l authPriv -u "$SNMP_V3_USER" -a SHA -A wrongauthpass123 -x AES -X "$SNMP_V3_PRIV_PASSWORD" -t 1 -r 0 -Oqv snmp .1.3.6.1.2.1.1.1.0 >/dev/null 2>&1'; then
  echo "SNMPv3 unexpectedly accepted wrong auth password"
  exit 1
fi

compose exec -T \
  -e SNMP_V3_USER="$snmp_v3_user" \
  -e SNMP_V3_PRIV_PASSWORD="$snmp_v3_priv_password" \
  attacker sh -lc '
    for i in $(seq 1 6); do
      snmpget -v2c -c public -t 1 -r 0 -Oqv snmp .1.3.6.1.2.1.1.1.0 >/dev/null 2>&1 || true
      snmpget -v3 -l authPriv -u "$SNMP_V3_USER" -a SHA -A wrongauthpass123 -x AES -X "$SNMP_V3_PRIV_PASSWORD" -t 1 -r 0 -Oqv snmp .1.3.6.1.2.1.1.1.0 >/dev/null 2>&1 || true
      sleep 1
    done
  '

for _ in $(seq 1 30); do
  if compose exec -T fail2ban fail2ban-client status snmp | grep -F "$attacker_ip" >/dev/null; then
    break
  fi
  sleep 2
done

if ! compose exec -T fail2ban fail2ban-client status snmp | grep -F "$attacker_ip" >/dev/null; then
  echo "Attacker IP was not banned: $attacker_ip"
  compose logs fail2ban "$service_name"
  exit 1
fi

if ! compose exec -T fail2ban sh -lc "iptables -S 2>/dev/null | grep -F '$attacker_ip' >/dev/null || iptables-legacy -S 2>/dev/null | grep -F '$attacker_ip' >/dev/null"; then
  echo "Fail2ban container iptables does not contain banned IP: $attacker_ip"
  exit 1
fi

assert_ip_not_banned_on_host "$attacker_ip"

echo "PASS [$service_name]: random community is enforced and fail2ban bans attacker IP in fail2ban container namespace only ($attacker_ip)"
