# Advanced configuration

## Fail2ban tuning

Файлы:

- `fail2ban/common/fail2ban.local` — глобальные настройки fail2ban daemon.
- `fail2ban/ssh/jail.local` — jail для SSH.

Можно настраивать:

- `maxretry`
- `findtime`
- `bantime`
- используемый `banaction`

После изменений пересоберите и перезапустите сервисы:

```bash
docker compose up -d --build fail2ban ssh
```

## SSH honeypot tuning

Файлы:

- `etc/ssh/sshd_config`
- `etc/ssh/rsyslog-sshd.conf`
- `etc/ssh/users.conf`

Важно: пароль в контейнере всегда генерируется динамически при старте и не задается статически в репозитории.
