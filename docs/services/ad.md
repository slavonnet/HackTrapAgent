# Active Directory (Samba) service implementation details

## Purpose

The AD service is used as an additional fail2ban event source for SMB authentication brute-force attempts.

## Runtime model

- The container runs `smbd` and exposes TCP `445`.
- Samba auth failures are written to `/var/log/ad/log.smbd`.
- This file is mounted via a shared volume and read by fail2ban.
- Anonymous guest access is disabled to force explicit credential guessing attempts.

## Credentials policy

- No static password is stored in the repository.
- New random passwords are generated on every container start for:
  - `root`
  - runtime service user from `etc/ad/users.conf`
- Current runtime credentials are written to `/run/hacktrap/ad_credentials.env` inside the container.

## Paths

- Build: `build/ad/`
- Config: `etc/ad/`
- Service defaults: `config/services.env`
- Test: `tests/ad/test_fail2ban_scope.sh`
- fail2ban jail: `fail2ban/ad/jail.local`
