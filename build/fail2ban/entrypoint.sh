#!/usr/bin/env bash
set -euo pipefail

mkdir -p /etc/fail2ban/jail.d /var/log/fail2ban /var/run/fail2ban

cp -f /opt/hacktrap/fail2ban/common/fail2ban.local /etc/fail2ban/fail2ban.local

if [[ -d /opt/hacktrap/fail2ban/filter.d ]]; then
  mkdir -p /etc/fail2ban/filter.d
  cp -f /opt/hacktrap/fail2ban/filter.d/*.conf /etc/fail2ban/filter.d/ 2>/dev/null || true
fi

services_raw="${FAIL2BAN_SERVICES:-ssh}"
IFS=',' read -ra services <<< "$services_raw"

for service in "${services[@]}"; do
  service="$(echo "$service" | xargs)"
  [[ -z "$service" ]] && continue

  source_filter_dir="/opt/hacktrap/fail2ban/${service}/filter.d"
  if [[ -d "$source_filter_dir" ]]; then
    mkdir -p /etc/fail2ban/filter.d
    for filter_file in "$source_filter_dir"/*; do
      [[ -f "$filter_file" ]] || continue
      cp -f "$filter_file" "/etc/fail2ban/filter.d/$(basename "$filter_file")"
    done
  fi

  source_jail="/opt/hacktrap/fail2ban/${service}/jail.local"
  target_jail="/etc/fail2ban/jail.d/${service}.local"
  if [[ -f "$source_jail" ]]; then
    cp -f "$source_jail" "$target_jail"
  else
    echo "WARN: no fail2ban jail for service '${service}' at ${source_jail}"
  fi

  source_filter="/opt/hacktrap/fail2ban/${service}/filter.conf"
  target_filter="/etc/fail2ban/filter.d/${service}.conf"
  if [[ -f "$source_filter" ]]; then
    cp -f "$source_filter" "$target_filter"
  fi
done

touch /var/log/fail2ban/fail2ban.log

if [[ ",${services_raw}," == *",ssh,"* ]]; then
  touch /var/log/ssh/auth.log
fi

if [[ ",${services_raw}," == *",ftp,"* ]]; then
  mkdir -p /var/log/ftp
  touch /var/log/ftp/vsftpd.log
fi

if [[ ",${services_raw}," == *",ntp,"* ]]; then
  mkdir -p /var/log/ntp
  touch /var/log/ntp/ntp.log
fi

if [[ ",${services_raw}," == *",bgp,"* ]]; then
  mkdir -p /var/log/bgp
  touch /var/log/bgp/bgp.log
fi

if [[ ",${services_raw}," == *",openvpn,"* ]]; then
  mkdir -p /var/log/openvpn
  touch /var/log/openvpn/openvpn.log
fi

if [[ ",${services_raw}," == *",mysql,"* ]]; then
  mkdir -p /var/log/mysql
  touch /var/log/mysql/error.log
fi

exec fail2ban-server -f -x -v
