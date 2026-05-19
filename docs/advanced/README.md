# Advanced configuration

## Fail2ban tuning

Files:

- `fail2ban/common/fail2ban.local` — global fail2ban daemon settings.
- `fail2ban/asterisk/jail.local` — Asterisk jail settings.
- `fail2ban/ssh/jail.local` — SSH jail settings.
- `fail2ban/ftp/jail.local` — FTP jail settings.
- `fail2ban/tftp/jail.local` — TFTP jail settings.
- `fail2ban/tftp/filter.conf` — TFTP failregex rules.
- `fail2ban/ntp/jail.local` — NTP jail settings.
- `fail2ban/imap/jail.local` — IMAP jail settings.
- `fail2ban/pop3/jail.local` — POP3 jail settings.
- `fail2ban/smtp/jail.local` — SMTP jail settings.
- `fail2ban/rdp/jail.local` — RDP jail settings.
- `fail2ban/rdp/filter.d/xrdp-sesman.conf` — RDP failregex for `AUTHFAIL` events.
- `fail2ban/ipsec/jail.local` — IPsec jail settings for L2TP and IKEv2 modes.
- `fail2ban/ipsec/filter.d/strongswan_ikev1.conf` — strongSwan IKEv1 filter template.
- `fail2ban/ipsec/filter.d/strongswan_ikev2.conf` — strongSwan IKEv2 filter template.
- `fail2ban/postgresql/jail.local` — PostgreSQL jail settings.
- `fail2ban/postgresql/filter.conf` — PostgreSQL failregex rules.
- `fail2ban/mysql/jail.local` — MySQL jail settings.
- `fail2ban/kafka/jail.local` — Kafka jail settings.
- `fail2ban/kafka/filter.conf` — Kafka failregex rules.
- `fail2ban/memcached/jail.local` — Memcached jail settings.
- `fail2ban/memcached/filter.conf` — Memcached failregex rules.
- `fail2ban/mongodb/jail.local` — MongoDB jail settings.
- `fail2ban/mongodb/filter.conf` — MongoDB JSON log failregex rules.
- `fail2ban/radius/jail.local` — RADIUS jail settings.
- `fail2ban/radius/filter.d/freeradius.conf` — RADIUS failregex rules.
- `fail2ban/redis/jail.local` — Redis jail settings.
- `fail2ban/redis/filter.conf` — Redis failregex rules.
- `fail2ban/elasticsearch/jail.local` — Elasticsearch jail settings.
- `fail2ban/elasticsearch/filter.conf` — Elasticsearch failregex rules.
- `fail2ban/clickhouse/jail.local` — ClickHouse jail settings.
- `fail2ban/clickhouse/filter.conf` — ClickHouse failregex rules.
- `config/services.env` — `FAIL2BAN_SERVICES` controls which jails are loaded.

You can tune:

- `maxretry`
- `findtime`
- `bantime`
- selected `banaction`

After changes, rebuild and restart services:

```bash
./scripts/compose_up.sh
```

## SSH honeypot tuning

Files:

- `etc/ssh/sshd_config`
- `etc/ssh/rsyslog-sshd.conf`
- `etc/ssh/users.conf`

Important: container password is always generated dynamically at startup and is never stored as a static value in the repository.

## FTP honeypot tuning

Files:

- `etc/ftp/vsftpd.conf`
- `etc/ftp/users.conf`

Important: container password is always generated dynamically at startup and is never stored as a static value in the repository.

## TFTP honeypot tuning

Files:

- `etc/tftp/tftpd.args`

TFTP has no protocol-level authentication. The honeypot keeps the root directory read-only and uses repeated denied write attempts as fail2ban signals.

## MySQL honeypot tuning

Files:

- `etc/mysql/mariadb-hacktrap.cnf`
- `etc/mysql/users.conf`

Important: container passwords are generated dynamically at startup and are never stored as static values in the repository.

## Memcached honeypot tuning

Files:

- `etc/memcached/users.conf`

Important: container password is generated dynamically at startup and is never stored as a static value in the repository.

## Redis honeypot tuning

Files:

- `etc/redis/redis.conf`
- `etc/redis/users.conf`

Important: Redis ACL passwords are generated dynamically at startup and are never stored as static values in the repository.

## PostgreSQL honeypot tuning

Files:

- `etc/postgresql/postgresql.conf`
- `etc/postgresql/pg_hba.conf`
- `etc/postgresql/users.conf`

Important: container passwords are generated dynamically at startup and are never stored as static values in the repository.

## Kafka honeypot tuning

Files:

- `etc/kafka/users.conf`

Important: container credentials are generated dynamically at startup and are never stored as static values in the repository.

## MongoDB honeypot tuning

Files:

- `etc/mongodb/users.conf`

## Elasticsearch honeypot tuning

Files:

- `etc/elasticsearch/users.conf`

Important: container passwords are generated dynamically at startup and are never stored as static values in the repository.

## ClickHouse honeypot tuning

Files:

- `etc/clickhouse/users.conf`

Important: container passwords are generated dynamically at startup and are never stored as static values in the repository.

## Service toggle and ports

Use `config/services.env` as a single source of truth:

- `ENABLED_SERVICES` — comma-separated enabled honeypot services.
- `<SERVICE>_PUBLIC_PORT` — host port for each service.
- Service containers use internal periodic self-termination every 1800 seconds; Docker restart policy relaunches them without any host-level Docker control loops.

## 5-minute service resource benchmark

Use the benchmark script to run all enabled services for 5 minutes, collect runtime metrics, and automatically stop the stack.

```bash
./scripts/benchmark_services.sh --duration-seconds 300
```

The script:

- starts `fail2ban` and all services from `ENABLED_SERVICES`,
- samples container stats every second,
- writes a report table and CSV to `reports/benchmarks/`,
- stops containers with `docker compose down -v --remove-orphans`.

Generated markdown table columns:

- `Port`
- `Service (docs)` (links to `docs/services/<service>.md`)
- `Image size`
- `Peak memory`
- `CPU time (core-seconds)`

The report also includes:

- `fail2ban` row (without public port, shown as `-`),
- `TOTAL` block under the table:
  - total image size in GB and GiB,
  - total CPU time in core-seconds,
  - peak memory for the whole container group (GB and GiB).

`CPU time (core-seconds)` is computed as an integral of sampled CPU usage:
`sum(CPU% / 100 * sample_interval_seconds)`.

Useful optional flags:

- `--sample-interval-seconds` (default: `1.0`)
- `--stats-timeout-seconds` (default: `5.0`) to prevent stuck `docker stats` calls
- `--output-file` and `--output-csv` to store results in custom paths

If Docker memory accounting is unavailable on the host, `Peak memory` is reported as `n/a`.

This report helps identify expensive services before tuning service-specific configuration files in `etc/<service>/...` (for example database durability/background settings).
