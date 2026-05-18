#!/usr/bin/env bash
set -euo pipefail

mkdir -p /var/log/bgp
touch /var/log/bgp/bgp.log
chmod 0644 /var/log/bgp/bgp.log

exec python3 /opt/hacktrap/bgp/server.py
