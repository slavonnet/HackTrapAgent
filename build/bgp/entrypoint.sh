#!/usr/bin/env bash
set -euo pipefail

peers_file="${BGP_PEERS_FILE:-/opt/hacktrap/etc/bgp/peers.conf}"
allowed_peers_env="${BGP_ALLOWED_PEERS:-}"
bgp_log_file="${BGP_LOG_FILE:-/var/log/bgp/bgp.log}"
bgpd_conf_file="${BGP_BGPD_CONF_FILE:-/etc/frr/bgpd.conf}"
local_asn="${BGP_LOCAL_ASN:-65000}"
peer_asn="${BGP_PEER_ASN:-65001}"
router_id="${BGP_ROUTER_ID:-198.51.100.1}"

mkdir -p /var/log/bgp /etc/frr
touch "$bgp_log_file"
chmod 0644 "$bgp_log_file"
mkdir -p /var/run/frr /var/tmp/frr

is_valid_ipv4() {
  local ip="$1"
  local octet
  local -a octets=()

  [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || return 1
  IFS='.' read -r -a octets <<< "$ip"
  for octet in "${octets[@]}"; do
    [[ "$octet" =~ ^[0-9]+$ ]] || return 1
    (( octet >= 0 && octet <= 255 )) || return 1
  done
}

declare -A configured_peers=()

register_peer() {
  local candidate="$1"
  if is_valid_ipv4 "$candidate"; then
    configured_peers["$candidate"]=1
  fi
}

if [[ -f "$peers_file" ]]; then
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"
    line="${line//,/ }"
    for token in $line; do
      register_peer "$token"
    done
  done < "$peers_file"
fi

for token in ${allowed_peers_env//,/ }; do
  register_peer "$token"
done

{
  cat <<EOF
frr defaults traditional
hostname bgp-honeypot
log file ${bgp_log_file} debugging
!
router bgp ${local_asn}
 bgp router-id ${router_id}
 bgp log-neighbor-changes
 no bgp ebgp-requires-policy
 no bgp network import-check
EOF

  for peer_ip in "${!configured_peers[@]}"; do
    printf ' neighbor %s remote-as %s\n' "$peer_ip" "$peer_asn"
  done

  cat <<'EOF'
!
debug bgp neighbor-events
!
line vty
!
EOF
} > "$bgpd_conf_file"

echo "Starting FRR bgpd with ${#configured_peers[@]} configured peer(s)."

bgpd_bin="$(command -v bgpd || true)"
if [[ -z "$bgpd_bin" ]] && [[ -x /usr/lib/frr/bgpd ]]; then
  bgpd_bin="/usr/lib/frr/bgpd"
fi

if [[ -z "$bgpd_bin" ]]; then
  echo "Cannot find bgpd binary."
  exit 1
fi

bgpd_args=(-f "$bgpd_conf_file" -A 0.0.0.0 -p 179 -n -Z -S)

exec "$bgpd_bin" "${bgpd_args[@]}"
