#!/usr/bin/env bash
set -euo pipefail


restart_interval="${RESTART_INTERVAL_SECONDS:-1800}"
if [[ ! "$restart_interval" =~ ^[0-9]+$ ]] || [[ "$restart_interval" -lt 1 ]]; then
  restart_interval=1800
fi

(
  while true; do
    sleep "$restart_interval"
    kill -TERM 1 2>/dev/null || exit 0
  done
) &

ntp_conf="/opt/hacktrap/etc/ntp/ntp.conf"
ntp_log_file="${NTP_LOG_FILE:-/var/log/ntp/ntp.log}"
ntp_debug_level="${NTP_DEBUG_LEVEL:-3}"

if [[ ! -f "$ntp_conf" ]]; then
  echo "Missing ntp config: $ntp_conf"
  exit 1
fi

mkdir -p /var/log/ntp /var/lib/ntpsec
touch "$ntp_log_file"
chmod 0644 "$ntp_log_file"

# Run real ntpd in foreground and persist verbose packet logs for fail2ban.
exec /usr/sbin/ntpd -n -g -D "$ntp_debug_level" -c "$ntp_conf" >>"$ntp_log_file" 2>&1
