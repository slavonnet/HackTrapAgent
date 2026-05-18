#!/usr/bin/env bash
set -euo pipefail

args_file="/opt/hacktrap/etc/tftp/tftpd.args"
log_file="/var/log/tftp/tftpd.log"
tftp_root="/srv/tftp"

mkdir -p /var/log/tftp "$tftp_root"
touch "$log_file"
chmod 0644 "$log_file"

# Keep the root read-only so write attempts are logged as denied actions.
chmod 0555 "$tftp_root"

# Create one readable decoy file for realistic RRQ traffic.
if [[ ! -f "${tftp_root}/readme.txt" ]]; then
  printf '%s\n' "HackTrapAgent TFTP service" > "${tftp_root}/readme.txt"
  chmod 0444 "${tftp_root}/readme.txt"
fi

read -r -a tftpd_args < "$args_file"

# in.tftpd logs to syslog; run a local syslog daemon to persist
# request lines into a shared file for fail2ban.
busybox syslogd -n -O "$log_file" &

exec /usr/sbin/in.tftpd "${tftpd_args[@]}"
