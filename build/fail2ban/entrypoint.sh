#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

mkdir -p /etc/fail2ban/jail.d /etc/fail2ban/filter.d /var/log/fail2ban /var/run/fail2ban

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

if [[ ",${services_raw}," == *",telnetd,"* ]]; then
  mkdir -p /var/log/telnet
  touch /var/log/telnet/auth.log
fi

if [[ ",${services_raw}," == *",ftp,"* ]]; then
  mkdir -p /var/log/ftp
  touch /var/log/ftp/vsftpd.log
fi

if [[ ",${services_raw}," == *",tftp,"* ]]; then
  mkdir -p /var/log/tftp
  touch /var/log/tftp/tftpd.log
fi

if [[ ",${services_raw}," == *",ntp,"* ]]; then
  mkdir -p /var/log/ntp
  touch /var/log/ntp/ntp.log
fi

if [[ ",${services_raw}," == *",nfs,"* ]]; then
  mkdir -p /var/log/nfs
  touch /var/log/nfs/ganesha.log
fi

if [[ ",${services_raw}," == *",asterisk,"* ]]; then
  mkdir -p /var/log/asterisk
  touch /var/log/asterisk/messages
fi

if [[ ",${services_raw}," == *",postgresql,"* ]]; then
  mkdir -p /var/log/postgresql
  touch /var/log/postgresql/postgresql.log
fi

if [[ ",${services_raw}," == *",mysql,"* ]]; then
  mkdir -p /var/log/mysql
  touch /var/log/mysql/error.log
fi

if [[ ",${services_raw}," == *",memcached,"* ]]; then
  mkdir -p /var/log/memcached
  touch /var/log/memcached/memcached.log
fi

if [[ ",${services_raw}," == *",elasticsearch,"* ]]; then
  mkdir -p /var/log/elasticsearch
  touch /var/log/elasticsearch/elasticsearch.log
fi

if [[ ",${services_raw}," == *",clickhouse,"* ]]; then
  mkdir -p /var/log/clickhouse-server
  touch /var/log/clickhouse-server/clickhouse-server.log
fi

if [[ ",${services_raw}," == *",redis,"* ]]; then
  mkdir -p /var/log/redis
  touch /var/log/redis/redis.log
  touch /var/log/redis/redis-auth.log
fi

if [[ ",${services_raw}," == *",mongodb,"* ]]; then
  mkdir -p /var/log/mongodb
  touch /var/log/mongodb/mongodb.log
fi

if [[ ",${services_raw}," == *",l2tp,"* ]]; then
  mkdir -p /var/log/l2tp
  touch /var/log/l2tp/charon.log
fi

if [[ ",${services_raw}," == *",ike2,"* ]]; then
  mkdir -p /var/log/ike2
  touch /var/log/ike2/charon.log
fi

if [[ ",${services_raw}," == *",imap,"* ]]; then
  mkdir -p /var/log/imap
  touch /var/log/imap/dovecot.log
fi

if [[ ",${services_raw}," == *",pop3,"* ]]; then
  mkdir -p /var/log/pop3
  touch /var/log/pop3/dovecot.log
fi

if [[ ",${services_raw}," == *",smtp,"* ]]; then
  mkdir -p /var/log/smtp
  touch /var/log/smtp/mail.log
fi

if [[ ",${services_raw}," == *",rabbitmq,"* ]]; then
  mkdir -p /var/log/rabbitmq
  touch /var/log/rabbitmq/rabbit.log
fi

if [[ ",${services_raw}," == *",bgp,"* ]]; then
  mkdir -p /var/log/bgp
  touch /var/log/bgp/bgp.log
fi

if [[ ",${services_raw}," == *",openvpn,"* ]]; then
  mkdir -p /var/log/openvpn
  touch /var/log/openvpn/openvpn.log
fi

if [[ ",${services_raw}," == *",smb,"* ]]; then
  mkdir -p /var/log/smb
  touch /var/log/smb/log.smbd
fi

if [[ ",${services_raw}," == *",kafka,"* ]]; then
  mkdir -p /var/log/kafka
  touch /var/log/kafka/kafka.log
fi

if [[ ",${services_raw}," == *",snmp,"* ]]; then
  mkdir -p /var/log/snmp
  touch /var/log/snmp/snmpd.log
fi

if [[ ",${services_raw}," == *",snmptrap,"* ]]; then
  mkdir -p /var/log/snmptrap
  touch /var/log/snmptrap/snmptrapd.log
fi

if [[ ",${services_raw}," == *",rdp,"* ]]; then
  mkdir -p /var/log/rdp
  touch /var/log/rdp/xrdp-sesman.log
fi

if [[ ",${services_raw}," == *",ad,"* ]]; then
  mkdir -p /var/log/ad
  touch /var/log/ad/slapd.log
fi

if [[ ",${services_raw}," == *",radius,"* ]]; then
  mkdir -p /var/log/radius
  touch /var/log/radius/radius.log
fi

exec fail2ban-server -f -x -v
