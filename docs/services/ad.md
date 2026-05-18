# Active Directory (LDAP) service implementation details

## Purpose

The AD service is used as an additional fail2ban event source for LDAP bind brute-force attempts.

## Runtime model

- The container runs `slapd` and exposes TCP `389`.
- LDAP auth failures are written to `/var/log/ad/slapd.log` via rsyslog.
- This file is mounted via a shared volume and read by fail2ban.
- Anonymous bind is disabled to force explicit credential guessing attempts.
- `fail2ban/ad/filter.d/slapd.conf` extends upstream `slapd` matching to cover OpenLDAP `RESULT ... err=49 qtime=... etime=...` lines.

## Credentials policy

- No static password is stored in the repository.
- New random passwords are generated on every container start for:
  - LDAP admin (`cn=admin,dc=hacktrap,dc=local`)
  - runtime service user from `etc/ad/users.conf`
- Current runtime credentials are written to `/run/hacktrap/ad_credentials.env` inside the container.

## Paths

- Build: `build/ad/`
- Config: `etc/ad/`
- Service defaults: `config/services.env`
- Test: `tests/ad/test_fail2ban_scope.sh`
- fail2ban jail: `fail2ban/ad/jail.local`
