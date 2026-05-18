#!/usr/bin/env bash
set -euo pipefail

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

default_password="$(openssl rand -hex 24)"
service_password="$(openssl rand -hex 24)"
default_password_sha256="$(printf "%s" "$default_password" | sha256sum | awk '{print $1}')"
service_password_sha256="$(printf "%s" "$service_password" | sha256sum | awk '{print $1}')"

mkdir -p /run/hacktrap /var/log/clickhouse-server /etc/clickhouse-server/users.d /etc/clickhouse-server/config.d
touch "$log_file" "$err_log_file"
chown -R clickhouse:clickhouse /run/hacktrap /var/log/clickhouse-server /etc/clickhouse-server/users.d /etc/clickhouse-server/config.d
chmod 0644 "$log_file" "$err_log_file"

if [[ "$user_name" == "default" ]]; then
  service_password="$default_password"
  service_password_sha256="$default_password_sha256"
fi

cat > "$users_config_path" <<EOF
<clickhouse>
  <users>
    <default>
      <password_sha256_hex>${default_password_sha256}</password_sha256_hex>
      <no_password remove="remove" />
      <networks>
        <ip>::/0</ip>
      </networks>
      <profile>default</profile>
      <quota>default</quota>
      <access_management>1</access_management>
    </default>
EOF

if [[ "$user_name" != "default" ]]; then
  cat >> "$users_config_path" <<EOF
    <${user_name}>
      <password_sha256_hex>${service_password_sha256}</password_sha256_hex>
      <networks>
        <ip>::/0</ip>
      </networks>
      <profile>default</profile>
      <quota>default</quota>
      <access_management>0</access_management>
    </${user_name}>
EOF
fi

cat >> "$users_config_path" <<'EOF'
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
  printf "CLICKHOUSE_DEFAULT_USER=default\n"
  printf "CLICKHOUSE_DEFAULT_PASSWORD=%s\n" "$default_password"
  printf "CLICKHOUSE_SERVICE_USER=%s\n" "$user_name"
  printf "CLICKHOUSE_SERVICE_PASSWORD=%s\n" "$service_password"
} > "$credentials_file"
chmod 600 "$credentials_file"
chown clickhouse:clickhouse "$users_config_path" "$logging_config_path" "$credentials_file"
echo "Generated random ClickHouse passwords for runtime users."

export CLICKHOUSE_SKIP_USER_SETUP=1
exec /entrypoint.sh "$@"
