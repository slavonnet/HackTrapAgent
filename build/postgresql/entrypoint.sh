#!/usr/bin/env bash
set -euo pipefail

user_name="${HACKTRAP_USER:-trap}"
users_file="/opt/hacktrap/etc/postgresql/users.conf"

if [[ -f "$users_file" ]]; then
  while IFS=: read -r cfg_user _; do
    [[ -z "${cfg_user// }" ]] && continue
    [[ "${cfg_user:0:1}" == "#" ]] && continue
    user_name="$cfg_user"
    break
  done < "$users_file"
fi

sql_escape_literal() {
  printf "%s" "$1" | sed "s/'/''/g"
}

cluster_line="$(pg_lsclusters --no-header | awk 'NR==1 {print $1 "|" $2 "|" $6}')"
if [[ -z "$cluster_line" ]]; then
  echo "Cannot detect PostgreSQL cluster."
  exit 1
fi

IFS='|' read -r version cluster cluster_data_dir <<< "$cluster_line"
cluster_config_dir="/etc/postgresql/${version}/${cluster}"
cluster_override_dir="${cluster_config_dir}/conf.d"

mkdir -p /var/log/postgresql /run/hacktrap /run/postgresql
touch /var/log/postgresql/postgresql.log
chmod 0644 /var/log/postgresql/postgresql.log
chown -R postgres:postgres /var/log/postgresql /run/postgresql "$cluster_data_dir"

mkdir -p "$cluster_override_dir"
cp -f /opt/hacktrap/etc/postgresql/pg_hba.conf "${cluster_config_dir}/pg_hba.conf"
cp -f /opt/hacktrap/etc/postgresql/postgresql.conf "${cluster_override_dir}/hacktrap.conf"
chown postgres:postgres "${cluster_config_dir}/pg_hba.conf" "${cluster_override_dir}/hacktrap.conf"

postgres_password="$(openssl rand -hex 24)"
service_password="$(openssl rand -hex 24)"
service_user_literal="$(sql_escape_literal "$user_name")"
postgres_password_literal="$(sql_escape_literal "$postgres_password")"
service_password_literal="$(sql_escape_literal "$service_password")"

pg_ctlcluster --skip-systemctl-redirect "$version" "$cluster" start

runuser -u postgres -- psql --dbname=postgres --set=ON_ERROR_STOP=1 <<SQL
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '${service_user_literal}') THEN
    EXECUTE format('CREATE ROLE %I LOGIN', '${service_user_literal}');
  END IF;
  EXECUTE format('ALTER ROLE postgres WITH PASSWORD %L', '${postgres_password_literal}');
  EXECUTE format('ALTER ROLE %I WITH LOGIN PASSWORD %L', '${service_user_literal}', '${service_password_literal}');
END
\$\$;
SQL

pg_ctlcluster --skip-systemctl-redirect "$version" "$cluster" stop

credentials_file="/run/hacktrap/postgresql_credentials.env"
{
  printf "POSTGRESQL_SUPERUSER=postgres\n"
  printf "POSTGRESQL_SUPERUSER_PASSWORD=%s\n" "$postgres_password"
  printf "POSTGRESQL_SERVICE_USER=%s\n" "$user_name"
  printf "POSTGRESQL_SERVICE_PASSWORD=%s\n" "$service_password"
} > "$credentials_file"
chmod 600 "$credentials_file"
chown postgres:postgres "$credentials_file"
echo "Generated random PostgreSQL passwords for runtime users."

exec pg_ctlcluster --skip-systemctl-redirect --foreground "$version" "$cluster" start
