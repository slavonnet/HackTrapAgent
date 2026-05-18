# Advanced configuration

## Fail2ban tuning

Files:

- `fail2ban/common/fail2ban.local` — global fail2ban daemon settings.
- `fail2ban/ssh/jail.local` — SSH jail settings.
- `fail2ban/ftp/jail.local` — FTP jail settings.
- `fail2ban/ntp/jail.local` — NTP jail settings.
- `fail2ban/imap/jail.local` — IMAP jail settings.
- `fail2ban/pop3/jail.local` — POP3 jail settings.
- `fail2ban/smtp/jail.local` — SMTP jail settings.
- `fail2ban/l2tp/jail.local` — L2TP jail settings.
- `fail2ban/ike2/jail.local` — IKEv2 jail settings.
- `fail2ban/l2tp/filter.d/strongswan_ikev1.conf` — strongSwan IKEv1 filter template.
- `fail2ban/ike2/filter.d/strongswan_ikev2.conf` — strongSwan IKEv2 filter template.
- `fail2ban/postgresql/jail.local` — PostgreSQL jail settings.
- `fail2ban/postgresql/filter.conf` — PostgreSQL failregex rules.
- `fail2ban/mysql/jail.local` — MySQL jail settings.
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

## MySQL honeypot tuning

Files:

- `etc/mysql/mariadb-hacktrap.cnf`
- `etc/mysql/users.conf`

Important: container passwords are generated dynamically at startup and are never stored as static values in the repository.

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
