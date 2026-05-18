# POP3 service implementation details

## Purpose

The POP3 service provides a mail-authentication honeypot endpoint that generates fail2ban events for repeated login failures.

## Runtime model

- The container runs upstream `dovecot-pop3d` on port `110`.
- Failed authentication attempts are written to `/var/log/pop3/dovecot.log`.
- The log file is mounted via a shared volume and consumed by fail2ban.
- fail2ban uses the upstream `dovecot` filter (no project-specific parser).

## Credentials policy

- No static password is stored in the repository.
- New random passwords are generated on every container start for both `root` and the service user.
- Current runtime credentials are written to `/run/hacktrap/pop3_credentials.env` inside the container.

## Paths

- Build: `build/pop3/`
- Config: `etc/pop3/`
- Service defaults: `config/services.env`
- Test: `tests/pop3/test_fail2ban_scope.sh`
- fail2ban jail: `fail2ban/pop3/jail.local`
