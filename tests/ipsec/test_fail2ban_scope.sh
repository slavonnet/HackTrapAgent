#!/usr/bin/env bash
set -euo pipefail

service_name="ipsec"
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# shellcheck source=tests/common/compose_test_lib.sh
source "${project_root}/tests/common/compose_test_lib.sh"

load_service_config
set_compose_project_name "$service_name"
target_user="${IPSEC_TEST_LOGIN_USER:-trap}"

trap cleanup_compose EXIT

init_docker_cmd
init_host_iptables_bins

compose --profile test up -d --build "$service_name" fail2ban attacker

wait_for_exec_success "$service_name" "pgrep -x charon"
wait_for_exec_success "fail2ban" "fail2ban-client ping"

attacker_ip="$(get_attacker_ip)"

if [[ -z "$attacker_ip" ]]; then
  echo "Cannot determine attacker IP"
  exit 1
fi

compose exec -T -e TARGET_USER="$target_user" attacker bash -lc '
set -euo pipefail

cat > /etc/ipsec.conf <<EOF
config setup
  uniqueids=no

conn l2tp-test
  keyexchange=ikev1
  authby=secret
  type=transport
  leftid=@untrusted-l2tp-client.hacktrap.local
  left=%defaultroute
  leftprotoport=17/1701
  right=ipsec
  rightid=@ipsec.hacktrap.local
  rightprotoport=17/1701
  ike=aes256-sha1-modp2048,aes128-sha1-modp1024!
  esp=aes256-sha1,aes128-sha1!
  auto=add
EOF

cat > /etc/ipsec.secrets <<EOF
: PSK "wrong-l2tp-psk"
EOF

ipsec restart >/dev/null 2>&1 || ipsec start >/dev/null 2>&1
sleep 2

for i in $(seq 1 6); do
  timeout 8 ipsec up l2tp-test >/dev/null 2>&1 || true
  timeout 3 ipsec down l2tp-test >/dev/null 2>&1 || true
  sleep 1
done
'

for _ in $(seq 1 30); do
  if compose exec -T fail2ban fail2ban-client status ipsec-l2tp | grep -F "$attacker_ip" >/dev/null; then
    break
  fi
  sleep 2
done

if ! compose exec -T fail2ban fail2ban-client status ipsec-l2tp | grep -F "$attacker_ip" >/dev/null; then
  echo "Attacker IP was not banned by ipsec-l2tp jail: $attacker_ip"
  compose logs fail2ban "$service_name"
  exit 1
fi

compose exec -T fail2ban fail2ban-client set ipsec-l2tp unbanip "$attacker_ip" >/dev/null

compose exec -T -e TARGET_USER="$target_user" attacker bash -lc '
set -euo pipefail

cat > /etc/ipsec.conf <<EOF
config setup
  uniqueids=no

conn ikev2-test
  keyexchange=ikev2
  auto=add
  leftauth=eap-mschapv2
  eap_identity=${TARGET_USER}
  right=ipsec
  rightid=@ipsec.hacktrap.local
  rightauth=pubkey
  ike=aes256-sha256-modp2048,aes128-sha256-modp2048!
  esp=aes256-sha256,aes128-sha256!
EOF

cat > /etc/ipsec.secrets <<EOF
${TARGET_USER} : EAP "wrong-ikev2-password"
EOF

ipsec restart >/dev/null 2>&1 || ipsec start >/dev/null 2>&1
sleep 2

for i in $(seq 1 6); do
  timeout 8 ipsec up ikev2-test >/dev/null 2>&1 || true
  timeout 3 ipsec down ikev2-test >/dev/null 2>&1 || true
  sleep 1
done
'

for _ in $(seq 1 30); do
  if compose exec -T fail2ban fail2ban-client status ipsec-ikev2 | grep -F "$attacker_ip" >/dev/null; then
    break
  fi
  sleep 2
done

if ! compose exec -T fail2ban fail2ban-client status ipsec-ikev2 | grep -F "$attacker_ip" >/dev/null; then
  echo "Attacker IP was not banned by ipsec-ikev2 jail: $attacker_ip"
  compose logs fail2ban "$service_name"
  exit 1
fi

if ! compose exec -T fail2ban sh -lc "iptables -S 2>/dev/null | grep -F '$attacker_ip' >/dev/null || iptables-legacy -S 2>/dev/null | grep -F '$attacker_ip' >/dev/null"; then
  echo "Fail2ban container iptables does not contain banned IP: $attacker_ip"
  exit 1
fi

assert_ip_not_banned_on_host "$attacker_ip"

echo "PASS [$service_name]: fail2ban bans attacker IP for both L2TP and IKEv2 jails in fail2ban namespace only ($attacker_ip)"
