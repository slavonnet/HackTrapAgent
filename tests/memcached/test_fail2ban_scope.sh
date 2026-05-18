#!/usr/bin/env bash
set -euo pipefail

service_name="memcached"
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# shellcheck source=tests/common/compose_test_lib.sh
source "${project_root}/tests/common/compose_test_lib.sh"

load_service_config
set_compose_project_name "$service_name"
target_user="${MEMCACHED_TEST_LOGIN_USER:-trap}"

trap cleanup_compose EXIT

init_docker_cmd
init_host_iptables_bins

compose --profile test up -d --build "$service_name" fail2ban attacker

wait_for_exec_success "$service_name" "python3 -c \"import socket; s=socket.create_connection(('127.0.0.1', 11211), 2); s.close()\""
wait_for_exec_success "fail2ban" "fail2ban-client ping"

attacker_ip="$(get_attacker_ip)"

if [[ -z "$attacker_ip" ]]; then
  echo "Cannot determine attacker IP"
  exit 1
fi

service_password="$(compose exec -T memcached sh -lc 'awk -F= "/^MEMCACHED_AUTH_PASSWORD=/{print \$2}" /run/hacktrap/memcached_credentials.env' | tr -d '\r')"
if [[ -z "$service_password" ]]; then
  echo "Cannot determine runtime memcached auth password"
  exit 1
fi

if ! compose exec -T -e TARGET_USER="$target_user" -e TARGET_PASSWORD="$service_password" attacker sh -lc '
  response="$({
    printf "auth %s %s\r\n" "$TARGET_USER" "$TARGET_PASSWORD"
    sleep 1
    printf "set probe 0 30 5\r\nhello\r\n"
    sleep 1
    printf "get probe\r\n"
    sleep 1
  } | nc -w3 memcached 11211 || true)"
  printf "%s" "$response" | grep -F "STORED" >/dev/null
  printf "%s" "$response" | grep -F "VALUE probe 0 5" >/dev/null
'; then
  echo "Authenticated memcached command flow failed"
  compose logs "$service_name"
  exit 1
fi

compose exec -T -e TARGET_USER="$target_user" attacker sh -lc '
  for i in $(seq 1 6); do
    printf "auth %s wrong-password\r\n" "$TARGET_USER" | nc -w1 memcached 11211 >/dev/null 2>&1 || true
    sleep 1
  done
'

for _ in $(seq 1 30); do
  if compose exec -T fail2ban fail2ban-client status memcached-auth | grep -F "$attacker_ip" >/dev/null; then
    break
  fi
  sleep 2
done

if ! compose exec -T fail2ban fail2ban-client status memcached-auth | grep -F "$attacker_ip" >/dev/null; then
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
