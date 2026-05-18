#!/usr/bin/env bash
set -euo pipefail

compose_file="${COMPOSE_FILE:-docker-compose.yml}"
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$project_root"

cleanup() {
  ${docker_cmd:-docker} compose -f "$compose_file" --profile test down -v --remove-orphans >/dev/null 2>&1 || true
}

trap cleanup EXIT

if ! command -v docker >/dev/null 2>&1; then
  echo "docker is required"
  exit 1
fi

docker_cmd="docker"
if ! docker info >/dev/null 2>&1; then
  if command -v sudo >/dev/null 2>&1 && sudo -n docker info >/dev/null 2>&1; then
    docker_cmd="sudo docker"
  else
    echo "Cannot access docker daemon."
    exit 1
  fi
fi

host_prefix=""
if command -v sudo >/dev/null 2>&1 && sudo -n true >/dev/null 2>&1; then
  host_prefix="sudo "
fi

host_iptables_bins=()
for bin in iptables iptables-legacy; do
  if command -v "$bin" >/dev/null 2>&1; then
    if ${host_prefix}${bin} -S >/dev/null 2>&1; then
      host_iptables_bins+=("$bin")
    fi
  fi
done

if [[ "${#host_iptables_bins[@]}" -eq 0 ]]; then
  echo "Cannot inspect host iptables; test cannot verify container-only scope."
  exit 1
fi

$docker_cmd compose -f "$compose_file" --profile test up -d --build ssh fail2ban attacker

for _ in $(seq 1 40); do
  if $docker_cmd compose -f "$compose_file" exec -T fail2ban fail2ban-client ping >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

if ! $docker_cmd compose -f "$compose_file" exec -T fail2ban fail2ban-client ping >/dev/null 2>&1; then
  echo "fail2ban did not become ready"
  exit 1
fi

attacker_ip="$($docker_cmd compose -f "$compose_file" exec -T attacker sh -lc "ip -4 -o addr show eth0 | awk '{print \$4}' | cut -d/ -f1" | tr -d '\r')"

if [[ -z "$attacker_ip" ]]; then
  echo "Cannot determine attacker IP"
  exit 1
fi

$docker_cmd compose -f "$compose_file" exec -T attacker sh -lc '
  for i in $(seq 1 6); do
    sshpass -p wrong ssh \
      -o StrictHostKeyChecking=no \
      -o UserKnownHostsFile=/dev/null \
      -o PreferredAuthentications=password \
      -o PubkeyAuthentication=no \
      -o ConnectTimeout=3 \
      trap@ssh "true" >/dev/null 2>&1 || true
    sleep 1
  done
'

for _ in $(seq 1 30); do
  if $docker_cmd compose -f "$compose_file" exec -T fail2ban fail2ban-client status sshd | grep -F "$attacker_ip" >/dev/null; then
    break
  fi
  sleep 2
done

if ! $docker_cmd compose -f "$compose_file" exec -T fail2ban fail2ban-client status sshd | grep -F "$attacker_ip" >/dev/null; then
  echo "Attacker IP was not banned: $attacker_ip"
  $docker_cmd compose -f "$compose_file" logs fail2ban ssh
  exit 1
fi

if ! $docker_cmd compose -f "$compose_file" exec -T fail2ban sh -lc "iptables -S 2>/dev/null | grep -F '$attacker_ip' >/dev/null || iptables-legacy -S 2>/dev/null | grep -F '$attacker_ip' >/dev/null"; then
  echo "Container iptables does not contain banned IP: $attacker_ip"
  exit 1
fi

for bin in "${host_iptables_bins[@]}"; do
  if ${host_prefix}${bin} -S | grep -F "$attacker_ip" >/dev/null; then
    echo "Host ${bin} unexpectedly contains banned IP: $attacker_ip"
    exit 1
  fi
done

if $docker_cmd compose -f "$compose_file" exec -T attacker sh -lc '
  sshpass -p trap123 ssh \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -o PreferredAuthentications=password \
    -o PubkeyAuthentication=no \
    -o ConnectTimeout=5 \
    trap@ssh "true"
' >/dev/null 2>&1; then
  echo "Attacker is still able to connect after ban"
  exit 1
fi

echo "PASS: fail2ban bans attacker IP in container namespace only ($attacker_ip)"
