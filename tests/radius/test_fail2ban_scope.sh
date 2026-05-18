#!/usr/bin/env bash
set -euo pipefail

service_name="radius"
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# shellcheck source=tests/common/compose_test_lib.sh
source "${project_root}/tests/common/compose_test_lib.sh"

load_service_config
set_compose_project_name "$service_name"
target_user="${RADIUS_TEST_LOGIN_USER:-trap}"

trap cleanup_compose EXIT

init_docker_cmd
init_host_iptables_bins

compose --profile test up -d --build "$service_name" fail2ban attacker

wait_for_exec_success "$service_name" "pgrep -x freeradius"
wait_for_exec_success "$service_name" "ss -lun | grep -q ':1812'"
wait_for_exec_success "fail2ban" "fail2ban-client ping"

attacker_ip="$(get_attacker_ip)"

if [[ -z "$attacker_ip" ]]; then
  echo "Cannot determine attacker IP"
  exit 1
fi

radius_secret="$(compose exec -T radius sh -lc "awk -F= '/^RADIUS_CLIENT_SECRET=/{print \$2}' /run/hacktrap/radius_credentials.env" | tr -d '\r')"
if [[ -z "$radius_secret" ]]; then
  echo "Cannot determine runtime RADIUS client secret"
  exit 1
fi

compose exec -T -e TARGET_USER="$target_user" -e RADIUS_SECRET="$radius_secret" attacker sh -lc '
  for i in $(seq 1 6); do
    radtest -t pap "$TARGET_USER" wrong radius 0 "$RADIUS_SECRET" >/dev/null 2>&1 || true
    sleep 1
  done
'

for _ in $(seq 1 30); do
  if compose exec -T fail2ban fail2ban-client status freeradius | grep -F "$attacker_ip" >/dev/null; then
    break
  fi
  sleep 2
done

if ! compose exec -T fail2ban fail2ban-client status freeradius | grep -F "$attacker_ip" >/dev/null; then
  echo "Attacker IP was not banned: $attacker_ip"
  compose logs fail2ban "$service_name"
  exit 1
fi

if ! compose exec -T fail2ban sh -lc "iptables -S 2>/dev/null | grep -F '$attacker_ip' >/dev/null || iptables-legacy -S 2>/dev/null | grep -F '$attacker_ip' >/dev/null"; then
  echo "Fail2ban container iptables does not contain banned IP: $attacker_ip"
  exit 1
fi

assert_ip_not_banned_on_host "$attacker_ip"

echo "PASS [$service_name]: fail2ban bans attacker IP in fail2ban container namespace only ($attacker_ip)"
