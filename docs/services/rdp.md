# RDP service implementation details

## Purpose

The RDP service provides an authentication-focused honeypot endpoint for fail2ban.

## Runtime model

- The container runs upstream `xrdp` and `xrdp-sesman` on port `3389`.
- Failed login attempts are written to `/var/log/rdp/xrdp-sesman.log`.
- This file is mounted via a shared volume and read by fail2ban.
- Authentication requires explicit credentials and is suitable for brute-force detection flows.

## Credentials policy

- No static password is stored in the repository.
- New random passwords are generated every time the container starts (including `root`).
- Current runtime credentials are written to `/run/hacktrap/rdp_credentials.env` inside the container.

## Paths

- Build: `build/rdp/`
- Config: `etc/rdp/`
- Service defaults: `config/services.env`
- Test: `tests/rdp/test_fail2ban_scope.sh`
- fail2ban jail: `fail2ban/rdp/jail.local`
- fail2ban filter: `fail2ban/rdp/filter.d/xrdp-sesman.conf`
