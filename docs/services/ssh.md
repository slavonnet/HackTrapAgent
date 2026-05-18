# SSH service implementation details

## Purpose

The SSH service is used as an event source for fail2ban (not as a production SSH endpoint).

## Runtime model

- The container runs `sshd` and `rsyslog`.
- `sshd` logs are written to `/var/log/ssh/auth.log`.
- This file is mounted via a shared volume and read by fail2ban.
- Root password login attempts are allowed and logged to match common real-world brute-force behavior.

## Credentials policy

- No static password is stored in the repository.
- New random passwords are generated every time the container starts (including `root`).
- Current runtime credentials are written to `/run/hacktrap/ssh_credentials.env` inside the container.

## Paths

- Build: `build/ssh/`
- Config: `etc/ssh/`
- Service defaults: `config/services.env`
- Test: `tests/ssh/test_fail2ban_scope.sh`
- fail2ban jail: `fail2ban/ssh/jail.local`
