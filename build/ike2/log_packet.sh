#!/usr/bin/env bash
set -euo pipefail

listen_port="${1:-0}"
peer_ip="${SOCAT_PEERADDR:-unknown}"
peer_port="${SOCAT_PEERPORT:-0}"
timestamp="$(date -u +'%Y-%m-%d %H:%M:%S')"

printf '%s charon[1]: peer=%s:%s ikev2 authentication failed on udp/%s: malformed proposal\n' \
  "$timestamp" "$peer_ip" "$peer_port" "$listen_port" >> /var/log/ike2/ike2.log
