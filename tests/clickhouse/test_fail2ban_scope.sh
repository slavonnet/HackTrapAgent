#!/usr/bin/env bash
set -euo pipefail

service_name="clickhouse"
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# shellcheck source=tests/common/compose_test_lib.sh
source "${project_root}/tests/common/compose_test_lib.sh"

load_service_config
set_compose_project_name "$service_name"
target_user="${CLICKHOUSE_TEST_LOGIN_USER:-trap}"

trap cleanup_compose EXIT

init_docker_cmd
init_host_iptables_bins

compose --profile test up -d --build "$service_name" fail2ban attacker

wait_for_exec_success "$service_name" "clickhouse-client --host 127.0.0.1 --port 9000 --user default --password \"\$(awk -F= '/^CLICKHOUSE_DEFAULT_PASSWORD=/{print \$2}' /run/hacktrap/clickhouse_credentials.env)\" --query \"SELECT 1\" >/dev/null"
wait_for_exec_success "fail2ban" "fail2ban-client ping"

attacker_ip="$(get_attacker_ip)"

if [[ -z "$attacker_ip" ]]; then
  echo "Cannot determine attacker IP"
  exit 1
fi

compose exec -T -e TARGET_USER="$target_user" attacker sh -lc '
  python3 - <<'"'"'PY'"'"'
import base64
import http.client
import os
import time

target_user = os.environ.get("TARGET_USER", "trap")
auth_raw = f"{target_user}:wrong".encode("utf-8")
auth_header = "Basic " + base64.b64encode(auth_raw).decode("ascii")

for _ in range(6):
    conn = http.client.HTTPConnection("clickhouse", 8123, timeout=3)
    try:
        conn.request(
            "POST",
            "/?query=SELECT+1",
            headers={"Authorization": auth_header},
        )
        response = conn.getresponse()
        response.read()
    except Exception:
        pass
    finally:
        conn.close()
    time.sleep(1)
PY
'

for _ in $(seq 1 30); do
  if compose exec -T fail2ban fail2ban-client status clickhouse-auth | grep -F "$attacker_ip" >/dev/null; then
    break
  fi
  sleep 2
done

if ! compose exec -T fail2ban fail2ban-client status clickhouse-auth | grep -F "$attacker_ip" >/dev/null; then
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
