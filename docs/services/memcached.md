# Memcached service implementation details

## Purpose

The Memcached service provides a realistic cache protocol surface with explicit credential guessing signals for fail2ban.

## Runtime model

- The container runs upstream `memcached` on an internal loopback port.
- A TCP auth proxy is exposed on port `11211` and requires `auth <user> <password>` before command forwarding.
- Failed auth attempts are logged to `/var/log/memcached/memcached.log`.
- After successful auth, real Memcached commands are forwarded to the backend daemon.
- The log file is mounted via a shared volume and consumed by fail2ban.

## Credentials policy

- No static password is stored in the repository.
- A random runtime password is generated for the configured auth user on each container start.
- Current runtime credentials are written to `/run/hacktrap/memcached_credentials.env` inside the container.

## Paths

- Build: `build/memcached/`
- Config: `etc/memcached/`
- Service defaults: `config/services.env`
- Test: `tests/memcached/test_fail2ban_scope.sh`
- fail2ban jail: `fail2ban/memcached/jail.local`
- fail2ban filter: `fail2ban/memcached/filter.conf`

## fail2ban filter choice

- The Debian `fail2ban` package used in this project does not ship a maintained Memcached auth filter.
- For this reason, the project keeps a dedicated service-local Memcached filter under `fail2ban/memcached/filter.conf`.
