#!/usr/bin/env bash
set -euo pipefail

read -r _payload || true

peer_addr="${SOCAT_PEERADDR:-0.0.0.0}"
peer_port="${SOCAT_PEERPORT:-0}"
user_name="${OPENVPN_HONEYPOT_USER:-trap}"
timestamp="$(date "+%Y-%m-%d %H:%M:%S")"

printf "%s openvpn[%s]: AUTH_FAILED [AF_INET]%s:%s user=%s\n" \
  "$timestamp" "$$" "$peer_addr" "$peer_port" "$user_name" >> /var/log/openvpn/openvpn.log
