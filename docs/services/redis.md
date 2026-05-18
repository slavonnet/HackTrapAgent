# Redis service implementation details

## Purpose

The Redis service is used as a fail2ban event source for repeated authentication attacks against Redis ACL users.

## Runtime model

- The container runs `redis-server` and exposes TCP `6379`.
- Redis logs are written to `/var/log/redis/redis.log`.
- This log file is mounted via a shared volume and monitored by fail2ban.
- Startup logic generates a random ACL password on each container start.

## Credentials policy

- No static password is stored in the repository.
- Startup generates a new random password for the runtime ACL user.
- If the configured runtime user is not `default`, anonymous/default ACL access is disabled.
- Current runtime credentials are written to `/run/hacktrap/redis_credentials.env` inside the container.

## Paths

- Build: `build/redis/`
- Config: `etc/redis/`
- Service defaults: `config/services.env`
- Test: `tests/redis/test_fail2ban_scope.sh`
- fail2ban jail: `fail2ban/redis/jail.local`
