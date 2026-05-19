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
users_file="/opt/hacktrap/etc/clickhouse/users.conf"
users_config_path="/etc/clickhouse-server/users.d/99-hacktrap-users.xml"
logging_config_path="/etc/clickhouse-server/config.d/99-hacktrap-logging.xml"
credentials_file="/run/hacktrap/clickhouse_credentials.env"
log_file="/var/log/clickhouse-server/clickhouse-server.log"
err_log_file="/var/log/clickhouse-server/clickhouse-server.err.log"

if [[ -f "$users_file" ]]; then
  while IFS=: read -r cfg_user _; do
    [[ -z "${cfg_user// }" ]] && continue
    [[ "${cfg_user:0:1}" == "#" ]] && continue
    user_name="$cfg_user"
    break
  done < "$users_file"
fi

if [[ ! "$user_name" =~ ^[A-Za-z0-9_]+$ ]]; then
  echo "Invalid ClickHouse runtime user: '$user_name'"
  exit 1
fi

service_password="$(openssl rand -hex 24)"
service_password_sha256="$(printf "%s" "$service_password" | sha256sum | awk '{print $1}')"

if [[ "$user_name" == "default" ]]; then
  echo "The default ClickHouse user is reserved for local-only access. Use a different runtime user."
  exit 1
fi

mkdir -p /run/hacktrap /var/log/clickhouse-server /etc/clickhouse-server/users.d /etc/clickhouse-server/config.d /var/lib/clickhouse/preprocessed_configs
touch "$log_file" "$err_log_file"
chown -R clickhouse:clickhouse /run/hacktrap /var/log/clickhouse-server /etc/clickhouse-server/users.d /etc/clickhouse-server/config.d /var/lib/clickhouse
chmod 0644 "$log_file" "$err_log_file"

cat > "$users_config_path" <<EOF
<clickhouse>
  <users>
    <default>
      <networks>
        <ip>127.0.0.1</ip>
        <ip>::1</ip>
      </networks>
      <profile>default</profile>
      <quota>default</quota>
      <access_management>0</access_management>
    </default>
    <${user_name}>
      <password_sha256_hex>${service_password_sha256}</password_sha256_hex>
      <networks>
        <ip>::/0</ip>
      </networks>
      <profile>default</profile>
      <quota>default</quota>
      <access_management>0</access_management>
    </${user_name}>
  </users>
</clickhouse>
EOF

cat > "$logging_config_path" <<EOF
<clickhouse>
  <logger>
    <level>information</level>
    <log>${log_file}</log>
    <errorlog>${err_log_file}</errorlog>
    <console>false</console>
  </logger>
  <profiles>
    <default>
      <log_queries>1</log_queries>
      <log_queries_min_type>QUERY_START</log_queries_min_type>
      <log_queries_cut_to_length>2048</log_queries_cut_to_length>
    </default>
  </profiles>
</clickhouse>
EOF

{
  printf "CLICKHOUSE_SERVICE_USER=%s\n" "$user_name"
  printf "CLICKHOUSE_SERVICE_PASSWORD=%s\n" "$service_password"
} > "$credentials_file"
chmod 600 "$credentials_file"
chown clickhouse:clickhouse "$users_config_path" "$logging_config_path" "$credentials_file"
echo "Generated random ClickHouse passwords for runtime users."

export CLICKHOUSE_SKIP_USER_SETUP=1
if [[ "$(id -u)" -eq 0 ]]; then
  exec runuser -u clickhouse -- /entrypoint.sh "$@"
fi
exec /entrypoint.sh "$@"
