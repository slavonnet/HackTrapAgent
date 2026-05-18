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
- `fail2ban/kafka/jail.local` — Kafka jail settings.
- `fail2ban/kafka/filter.conf` — Kafka failregex rules.
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

## Service toggle and ports

Use `config/services.env` as a single source of truth:

- `ENABLED_SERVICES` — comma-separated enabled honeypot services.
- `<SERVICE>_PUBLIC_PORT` — host port for each service.
