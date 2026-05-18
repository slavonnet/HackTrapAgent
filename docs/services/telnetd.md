# Telnet service implementation details

## Purpose

The Telnet service is used as an additional fail2ban event source for brute-force password attempts.

## Runtime model

- The container runs `in.telnetd` and `rsyslog`.
- PAM authentication logs are written to `/var/log/telnet/auth.log`.
- This file is mounted via a shared volume and read by fail2ban.
- Password authentication is intentionally enabled to capture realistic failed login traffic.

## Credentials policy

- No static password is stored in the repository.
- New random passwords are generated on every container start for both `root` and the service user.
- Current runtime credentials are written to `/run/hacktrap/telnetd_credentials.env` inside the container.

## Paths

- Build: `build/telnetd/`
- Config: `etc/telnetd/`
- Service defaults: `config/services.env`
- Test: `tests/telnetd/test_fail2ban_scope.sh`
- fail2ban jail: `fail2ban/telnetd/jail.local`
