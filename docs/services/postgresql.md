# PostgreSQL service implementation details

## Purpose

The PostgreSQL service is used as an additional fail2ban event source for password brute-force login attempts.

## Runtime model

- The container runs PostgreSQL with TCP access on port `5432`.
- Authentication failures are logged to `/var/log/postgresql/postgresql.log`.
- This file is mounted via a shared volume and read by fail2ban.
- Password authentication over TCP is enabled to capture realistic failed login traffic.

## Credentials policy

- No static password is stored in the repository.
- New random passwords are generated on every container start for `postgres` and the service user.
- Current runtime credentials are written to `/run/hacktrap/postgresql_credentials.env` inside the container.

## Paths

- Build: `build/postgresql/`
- Config: `etc/postgresql/`
- Service defaults: `config/services.env`
- Test: `tests/postgresql/test_fail2ban_scope.sh`
- fail2ban jail: `fail2ban/postgresql/jail.local`
