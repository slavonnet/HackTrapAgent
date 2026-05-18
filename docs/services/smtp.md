# SMTP service implementation details

## Purpose

The SMTP service provides a mail-authentication honeypot endpoint that generates fail2ban events for repeated login failures.

## Runtime model

- The container runs upstream `postfix` SMTP daemon on port `25`.
- Failed authentication attempts are written to `/var/log/smtp/mail.log`.
- The log file is mounted via a shared volume and consumed by fail2ban.
- fail2ban uses the upstream `postfix` filter in `mode=auth`.

## Credentials policy

- No static password is stored in the repository.
- New random passwords are generated on every container start for both `root` and the service user.
- Current runtime credentials are written to `/run/hacktrap/smtp_credentials.env` inside the container.

## Paths

- Build: `build/smtp/`
- Config: `etc/smtp/`
- Service defaults: `config/services.env`
- Test: `tests/smtp/test_fail2ban_scope.sh`
- fail2ban jail: `fail2ban/smtp/jail.local`
