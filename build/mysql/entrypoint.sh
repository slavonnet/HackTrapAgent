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

user_name="${HACKTRAP_USER:-trap}"
users_file="/opt/hacktrap/etc/mysql/users.conf"
datadir="/var/lib/mysql"
socket_file="/run/mysqld/mysqld.sock"
pid_file="/run/mysqld/mysqld.pid"
error_log="/var/log/mysql/error.log"

if [[ -f "$users_file" ]]; then
  while IFS=: read -r cfg_user _; do
    [[ -z "${cfg_user// }" ]] && continue
    [[ "${cfg_user:0:1}" == "#" ]] && continue
    user_name="$cfg_user"
    break
  done < "$users_file"
fi

if [[ ! "$user_name" =~ ^[A-Za-z0-9_]+$ ]]; then
  echo "Invalid mysql runtime user: '$user_name'"
  exit 1
fi

mkdir -p /run/mysqld /var/log/mysql /run/hacktrap "$datadir"
touch "$error_log"
chown -R mysql:mysql /run/mysqld /var/log/mysql "$datadir"

if [[ ! -d "${datadir}/mysql" ]]; then
  mariadb-install-db --user=mysql --datadir="$datadir" >/dev/null
fi

/usr/sbin/mariadbd \
  --user=mysql \
  --datadir="$datadir" \
  --socket="$socket_file" \
  --pid-file="$pid_file" \
  --skip-networking \
  --log-error="$error_log" &
temp_pid="$!"

for _ in $(seq 1 30); do
  if mariadb-admin --protocol=socket --socket="$socket_file" ping >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

if ! mariadb-admin --protocol=socket --socket="$socket_file" ping >/dev/null 2>&1; then
  echo "Temporary mariadb server did not become ready."
  exit 1
fi

root_password="$(openssl rand -hex 24)"
service_password=""

if [[ "$user_name" != "root" ]]; then
  service_password="$(openssl rand -hex 24)"
fi

if [[ "$user_name" == "root" ]]; then
  mariadb --protocol=socket --socket="$socket_file" -uroot <<SQL
CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '${root_password}';
ALTER USER 'root'@'%' IDENTIFIED BY '${root_password}';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
SQL
else
  mariadb --protocol=socket --socket="$socket_file" -uroot <<SQL
CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '${root_password}';
ALTER USER 'root'@'%' IDENTIFIED BY '${root_password}';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
CREATE USER IF NOT EXISTS '${user_name}'@'%' IDENTIFIED BY '${service_password}';
ALTER USER '${user_name}'@'%' IDENTIFIED BY '${service_password}';
GRANT USAGE ON *.* TO '${user_name}'@'%';
FLUSH PRIVILEGES;
SQL
fi

mariadb-admin --protocol=socket --socket="$socket_file" -uroot shutdown >/dev/null
wait "$temp_pid"

credentials_file="/run/hacktrap/mysql_credentials.env"
{
  printf "MYSQL_ROOT_USER=root\nMYSQL_ROOT_PASSWORD=%s\n" "$root_password"
  if [[ "$user_name" != "root" ]]; then
    printf "MYSQL_SERVICE_USER=%s\nMYSQL_SERVICE_PASSWORD=%s\n" "$user_name" "$service_password"
  fi
} > "$credentials_file"
chmod 600 "$credentials_file"
echo "Generated random MySQL passwords for runtime users."

exec /usr/sbin/mariadbd \
  --user=mysql \
  --datadir="$datadir" \
  --socket="$socket_file" \
  --pid-file="$pid_file" \
  --log-error="$error_log"
