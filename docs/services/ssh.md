# SSH service implementation details

## Purpose

SSH-сервис используется как источник событий для fail2ban (не как production SSH endpoint).

## Runtime model

- Контейнер запускает `sshd` и `rsyslog`.
- Логи `sshd` пишутся в `/var/log/ssh/auth.log`.
- Этот файл монтируется в общий volume и читается fail2ban.

## Credentials policy

- Статический пароль в репозитории отсутствует.
- При каждом старте контейнера генерируется новый случайный пароль.
- Текущие runtime credentials сохраняются в `/run/hacktrap/ssh_credentials.env` внутри контейнера.

## Paths

- Build: `build/ssh/`
- Config: `etc/ssh/`
- Test: `tests/ssh/test_fail2ban_scope.sh`
- fail2ban jail: `fail2ban/ssh/jail.local`
