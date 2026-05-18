# Advanced configuration

## Fail2ban tuning

Files:

- `fail2ban/common/fail2ban.local` — global fail2ban daemon settings.
- `fail2ban/ssh/jail.local` — SSH jail settings.
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

## Service toggle and ports

Use `config/services.env` as a single source of truth:

- `ENABLED_SERVICES` — comma-separated enabled honeypot services.
- `<SERVICE>_PUBLIC_PORT` — host port for each service.
