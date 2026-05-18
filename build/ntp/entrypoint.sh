#!/usr/bin/env bash
set -euo pipefail

config_file="/opt/hacktrap/etc/ntp/ntp-honeypot.conf"
if [[ -f "$config_file" ]]; then
  set -a
  # shellcheck source=/dev/null
  source "$config_file"
  set +a
fi

: "${NTP_LISTEN_PORT:=123}"
: "${NTP_LOG_FILE:=/var/log/ntp/ntp.log}"

mkdir -p "$(dirname "$NTP_LOG_FILE")"
touch "$NTP_LOG_FILE"
chmod 0644 "$NTP_LOG_FILE"

exec python3 /usr/local/bin/ntp-honeypot.py
