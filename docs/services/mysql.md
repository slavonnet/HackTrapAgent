# MySQL service implementation details

## Purpose

The MySQL service is used as an additional fail2ban event source for brute-force authentication attempts.

## Runtime model

- The container runs `mariadbd` and exposes TCP `3306`.
- MySQL auth errors are written to `/var/log/mysql/error.log`.
- This file is mounted via a shared volume and read by fail2ban.
- Startup logic keeps local socket admin access and rotates remote credentials on every container start.

## Credentials policy

- No static password is stored in the repository.
- New random passwords are generated on each container start for:
  - `root` remote login (`root@%`)
  - optional runtime service user from `etc/mysql/users.conf`
- Current runtime credentials are written to `/run/hacktrap/mysql_credentials.env` inside the container.

## Paths

- Build: `build/mysql/`
- Config: `etc/mysql/`
- Service defaults: `config/services.env`
- Test: `tests/mysql/test_fail2ban_scope.sh`
- fail2ban jail: `fail2ban/mysql/jail.local`
