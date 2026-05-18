#!/usr/bin/env bash
set -euo pipefail

mkdir -p /etc/fail2ban/jail.d /etc/fail2ban/filter.d /var/log/fail2ban /var/run/fail2ban

cp -f /opt/hacktrap/fail2ban/common/fail2ban.local /etc/fail2ban/fail2ban.local

services_raw="${FAIL2BAN_SERVICES:-ssh}"
IFS=',' read -ra services <<< "$services_raw"

for service in "${services[@]}"; do
  service="$(echo "$service" | xargs)"
  [[ -z "$service" ]] && continue

  source_jail="/opt/hacktrap/fail2ban/${service}/jail.local"
  target_jail="/etc/fail2ban/jail.d/${service}.local"
  if [[ -f "$source_jail" ]]; then
    cp -f "$source_jail" "$target_jail"
  else
    echo "WARN: no fail2ban jail for service '${service}' at ${source_jail}"
  fi

  source_filter_dir="/opt/hacktrap/fail2ban/${service}/filter.d"
  if [[ -d "$source_filter_dir" ]]; then
    shopt -s nullglob
    for source_filter in "$source_filter_dir"/*.conf; do
      cp -f "$source_filter" "/etc/fail2ban/filter.d/$(basename "$source_filter")"
    done
    shopt -u nullglob
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

if [[ ",${services_raw}," == *",l2tp,"* ]]; then
  mkdir -p /var/log/l2tp
  touch /var/log/l2tp/l2tp.log
fi

if [[ ",${services_raw}," == *",ike2,"* ]]; then
  mkdir -p /var/log/ike2
  touch /var/log/ike2/ike2.log
fi

exec fail2ban-server -f -x -v
