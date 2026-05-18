# Advanced configuration

## Fail2ban tuning

Files:

- `fail2ban/common/fail2ban.local` — global fail2ban daemon settings.
- `fail2ban/ssh/jail.local` — SSH jail settings.

You can tune:

- `maxretry`
- `findtime`
- `bantime`
- selected `banaction`

After changes, rebuild and restart services:

```bash
docker compose up -d --build fail2ban ssh
```

## SSH honeypot tuning

Files:

- `etc/ssh/sshd_config`
- `etc/ssh/rsyslog-sshd.conf`
- `etc/ssh/users.conf`

Important: container password is always generated dynamically at startup and is never stored as a static value in the repository.
