#!/usr/bin/env bash
set -euo pipefail

service_name="nfs"
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# shellcheck source=tests/common/compose_test_lib.sh
source "${project_root}/tests/common/compose_test_lib.sh"

load_service_config
set_compose_project_name "$service_name"

trap cleanup_compose EXIT

init_docker_cmd
init_host_iptables_bins

compose --profile test up -d --build "$service_name" fail2ban attacker

wait_for_exec_success "$service_name" "pgrep -f ganesha.nfsd"
wait_for_exec_success "fail2ban" "fail2ban-client ping"

attacker_ip="$(get_attacker_ip)"

if [[ -z "$attacker_ip" ]]; then
  echo "Cannot determine attacker IP"
  exit 1
fi

compose exec -T attacker sh -lc '
  # Send valid NFSv4 RPC NULL probes without requiring mount privileges.
  # This keeps the test deterministic in restricted CI environments.
  for i in $(seq 1 6); do
    python3 - "$i" <<'"'"'PY'"'"' >/dev/null 2>&1 || true
import socket
import struct
import sys

xid = 0x12340000 + int(sys.argv[1])
body = struct.pack(
    ">10I",
    xid,
    0,      # CALL
    2,      # RPC version
    100003, # NFS program
    4,      # NFS version
    0,      # NULL procedure
    0, 0,   # AUTH_NULL credentials
    0, 0,   # AUTH_NULL verifier
)
record_mark = struct.pack(">I", 0x80000000 | len(body))

with socket.create_connection(("nfs", 2049), timeout=2) as conn:
    conn.sendall(record_mark + body)
    conn.settimeout(2)
    try:
        conn.recv(1024)
    except OSError:
        pass
PY
    sleep 1
  done
'

for _ in $(seq 1 30); do
  if compose exec -T fail2ban fail2ban-client status nfs-ganesha-rpc | grep -F "$attacker_ip" >/dev/null; then
    break
  fi
  sleep 2
done

if ! compose exec -T fail2ban fail2ban-client status nfs-ganesha-rpc | grep -F "$attacker_ip" >/dev/null; then
  echo "Attacker IP was not banned: $attacker_ip"
  echo "Recent nfs-ganesha log tail:"
  compose exec -T nfs sh -lc "tail -n 80 /var/log/nfs/ganesha.log || true"
  compose logs fail2ban "$service_name"
  exit 1
fi

if ! compose exec -T fail2ban sh -lc "iptables -S 2>/dev/null | grep -F '$attacker_ip' >/dev/null || iptables-legacy -S 2>/dev/null | grep -F '$attacker_ip' >/dev/null"; then
  echo "Fail2ban container iptables does not contain banned IP: $attacker_ip"
  exit 1
fi

assert_ip_not_banned_on_host "$attacker_ip"

echo "PASS [$service_name]: fail2ban bans attacker IP in fail2ban container namespace only ($attacker_ip)"
