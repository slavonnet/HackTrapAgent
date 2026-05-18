#!/usr/bin/env bash
set -euo pipefail

service_name="asterisk"
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# shellcheck source=tests/common/compose_test_lib.sh
source "${project_root}/tests/common/compose_test_lib.sh"

load_service_config
set_compose_project_name "$service_name"
target_user="${ASTERISK_TEST_LOGIN_USER:-trap}"

trap cleanup_compose EXIT

init_docker_cmd
init_host_iptables_bins

compose --profile test up -d --build "$service_name" fail2ban attacker

wait_for_exec_success "$service_name" "asterisk -rx 'core show version' >/dev/null"
wait_for_exec_success "$service_name" "ss -lun | grep -F ':4569 '"
wait_for_exec_success "$service_name" "ss -lun | grep -F ':5060 '"
wait_for_exec_success "$service_name" "ss -ltn | grep -F ':5038 '"
wait_for_exec_success "$service_name" "ss -ltn | grep -F ':8088 '"
wait_for_exec_success "fail2ban" "fail2ban-client ping"

attacker_ip="$(get_attacker_ip)"

if [[ -z "$attacker_ip" ]]; then
  echo "Cannot determine attacker IP"
  exit 1
fi

compose exec -T -e TARGET_USER="$target_user" attacker sh -lc '
  for i in $(seq 1 6); do
    {
      printf "Action: Login\r\n"
      printf "Username: %s\r\n" "$TARGET_USER"
      printf "Secret: wrong\r\n"
      printf "Events: off\r\n\r\n"
      sleep 1
    } | nc -w 3 asterisk 5038 >/dev/null 2>&1 || true
    sleep 1
  done

  for i in $(seq 1 6); do
    python3 - <<PY >/dev/null 2>&1 || true
import base64
import urllib.request

credentials = base64.b64encode(f"${TARGET_USER}:wrong".encode()).decode()
request = urllib.request.Request("http://asterisk:8088/ari/asterisk/info")
request.add_header("Authorization", f"Basic {credentials}")

try:
    urllib.request.urlopen(request, timeout=2)
except Exception:
    pass
PY
    sleep 1
  done

  for i in $(seq 1 6); do
    {
      printf "REGISTER sip:asterisk SIP/2.0\r\n"
      printf "Via: SIP/2.0/UDP attacker;branch=z9hG4bK%s\r\n" "$i"
      printf "From: <sip:%s@asterisk>;tag=%s\r\n" "$TARGET_USER" "$i"
      printf "To: <sip:%s@asterisk>\r\n" "$TARGET_USER"
      printf "Call-ID: hacktrap-%s@attacker\r\n" "$i"
      printf "CSeq: 1 REGISTER\r\n"
      printf "Contact: <sip:%s@attacker>\r\n" "$TARGET_USER"
      printf "Max-Forwards: 70\r\n"
      printf "Content-Length: 0\r\n\r\n"
    } | nc -u -w 1 asterisk 5060 >/dev/null 2>&1 || true
    sleep 1
  done
'

for _ in $(seq 1 30); do
  if compose exec -T fail2ban fail2ban-client status asterisk | grep -F "$attacker_ip" >/dev/null; then
    break
  fi
  sleep 2
done

if ! compose exec -T fail2ban fail2ban-client status asterisk | grep -F "$attacker_ip" >/dev/null; then
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
