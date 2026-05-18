#!/usr/bin/env bash
set -euo pipefail

service_name="snmptrap"
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# shellcheck source=tests/common/compose_test_lib.sh
source "${project_root}/tests/common/compose_test_lib.sh"

load_service_config
set_compose_project_name "$service_name"

trap cleanup_compose EXIT

init_docker_cmd
init_host_iptables_bins

compose --profile test up -d --build "$service_name" fail2ban attacker

wait_for_exec_success "$service_name" "pgrep -x snmptrapd"
wait_for_exec_success "fail2ban" "fail2ban-client ping"

attacker_ip="$(get_attacker_ip)"

if [[ -z "$attacker_ip" ]]; then
  echo "Cannot determine attacker IP"
  exit 1
fi

snmptrap_community="$(compose exec -T "$service_name" sh -lc '. /run/hacktrap/snmptrap_credentials.env && printf "%s" "$SNMPTRAP_V2C_COMMUNITY"')"
snmptrap_v3_user="$(compose exec -T "$service_name" sh -lc '. /run/hacktrap/snmptrap_credentials.env && printf "%s" "$SNMPTRAP_V3_USER"')"
snmptrap_v3_auth_password="$(compose exec -T "$service_name" sh -lc '. /run/hacktrap/snmptrap_credentials.env && printf "%s" "$SNMPTRAP_V3_AUTH_PASSWORD"')"
snmptrap_v3_priv_password="$(compose exec -T "$service_name" sh -lc '. /run/hacktrap/snmptrap_credentials.env && printf "%s" "$SNMPTRAP_V3_PRIV_PASSWORD"')"

if [[ -z "$snmptrap_community" || -z "$snmptrap_v3_user" || -z "$snmptrap_v3_auth_password" || -z "$snmptrap_v3_priv_password" ]]; then
  echo "SNMP trap runtime credentials are missing"
  exit 1
fi

if ! compose exec -T -e SNMPTRAP_COMMUNITY="$snmptrap_community" attacker sh -lc 'snmptrap -v2c -c "$SNMPTRAP_COMMUNITY" -t 1 -r 0 snmptrap "" .1.3.6.1.6.3.1.1.5.1 >/dev/null 2>&1'; then
  echo "SNMP trap service did not accept generated random community"
  exit 1
fi

if ! compose exec -T \
  -e SNMPTRAP_V3_USER="$snmptrap_v3_user" \
  -e SNMPTRAP_V3_AUTH_PASSWORD="$snmptrap_v3_auth_password" \
  -e SNMPTRAP_V3_PRIV_PASSWORD="$snmptrap_v3_priv_password" \
  attacker sh -lc 'snmptrap -v3 -l authPriv -u "$SNMPTRAP_V3_USER" -a SHA -A "$SNMPTRAP_V3_AUTH_PASSWORD" -x AES -X "$SNMPTRAP_V3_PRIV_PASSWORD" -t 1 -r 0 snmptrap "" .1.3.6.1.6.3.1.1.5.1 >/dev/null 2>&1'; then
  echo "SNMP trap service did not accept SNMPv3 generated credentials"
  exit 1
fi

compose exec -T \
  -e SNMPTRAP_V3_USER="$snmptrap_v3_user" \
  -e SNMPTRAP_V3_PRIV_PASSWORD="$snmptrap_v3_priv_password" \
  attacker sh -lc '
    for i in $(seq 1 8); do
      snmptrap -v2c -c public -t 1 -r 0 snmptrap "" .1.3.6.1.6.3.1.1.5.1 >/dev/null 2>&1 || true
      snmptrap -v2c -c private -t 1 -r 0 snmptrap "" .1.3.6.1.6.3.1.1.5.1 >/dev/null 2>&1 || true
      snmptrap -v3 -l authPriv -u "$SNMPTRAP_V3_USER" -a SHA -A wrongauthpass123 -x AES -X "$SNMPTRAP_V3_PRIV_PASSWORD" -t 1 -r 0 snmptrap "" .1.3.6.1.6.3.1.1.5.1 >/dev/null 2>&1 || true
      sleep 1
    done
  '

for _ in $(seq 1 30); do
  if compose exec -T fail2ban fail2ban-client status snmptrap | grep -F "$attacker_ip" >/dev/null; then
    break
  fi
  sleep 2
done

if ! compose exec -T fail2ban fail2ban-client status snmptrap | grep -F "$attacker_ip" >/dev/null; then
  echo "Attacker IP was not banned: $attacker_ip"
  compose logs fail2ban "$service_name"
  exit 1
fi

if ! compose exec -T fail2ban sh -lc "iptables -S 2>/dev/null | grep -F '$attacker_ip' >/dev/null || iptables-legacy -S 2>/dev/null | grep -F '$attacker_ip' >/dev/null"; then
  echo "Fail2ban container iptables does not contain banned IP: $attacker_ip"
  exit 1
fi

assert_ip_not_banned_on_host "$attacker_ip"

echo "PASS [$service_name]: SNMP trap auth checks generate fail2ban bans in container namespace only ($attacker_ip)"
