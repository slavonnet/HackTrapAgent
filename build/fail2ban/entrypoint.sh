#!/usr/bin/env bash
set -euo pipefail

mkdir -p /etc/fail2ban/jail.d /var/log/fail2ban /var/run/fail2ban

cp -f /opt/hacktrap/fail2ban/common/fail2ban.local /etc/fail2ban/fail2ban.local
cp -f /opt/hacktrap/fail2ban/ssh/jail.local /etc/fail2ban/jail.d/ssh.local

touch /var/log/fail2ban/fail2ban.log
touch /var/log/ssh/auth.log

exec fail2ban-server -f -x -v
