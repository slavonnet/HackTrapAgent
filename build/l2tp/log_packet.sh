#!/usr/bin/env bash
set -euo pipefail

peer_ip="${SOCAT_PEERADDR:-unknown}"
peer_port="${SOCAT_PEERPORT:-0}"
timestamp="$(date -u +'%Y-%m-%d %H:%M:%S')"

printf '%s l2tpd[1]: peer=%s:%s auth failed: invalid tunnel setup\n' \
  "$timestamp" "$peer_ip" "$peer_port" >> /var/log/l2tp/l2tp.log
