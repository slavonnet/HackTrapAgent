# ClickHouse service implementation details

## Purpose

The ClickHouse service provides a realistic SQL analytics endpoint that emits fail2ban events for repeated authentication failures.

## Runtime model

- The container runs ClickHouse server and exposes:
  - native TCP protocol on `9000`
  - HTTP SQL interface on `8123`
- Authentication failures are logged to `/var/log/clickhouse-server/clickhouse-server.log`.
- SQL requests are logged with query logging enabled in the default profile.
- The log file is mounted via a shared volume and consumed by fail2ban.

## Credentials policy

- No static password is stored in the repository.
- New random passwords are generated on every container start for:
  - `default` user
  - runtime service user from `etc/clickhouse/users.conf`
- Anonymous/no-password default access is explicitly removed at startup.
- Current runtime credentials are written to `/run/hacktrap/clickhouse_credentials.env` inside the container.

## fail2ban filter choice

- The default fail2ban filter set does not ship a maintained ClickHouse authentication filter.
- The project uses a service-local filter at `fail2ban/clickhouse/filter.conf` to match ClickHouse authentication failures with source IP.

## Paths

- Build: `build/clickhouse/`
- Config: `etc/clickhouse/`
- Service defaults: `config/services.env`
- Test: `tests/clickhouse/test_fail2ban_scope.sh`
- fail2ban jail: `fail2ban/clickhouse/jail.local`
- fail2ban filter: `fail2ban/clickhouse/filter.conf`
