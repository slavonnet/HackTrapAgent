# RADIUS service implementation details

## Purpose

The RADIUS service provides a UDP authentication honeypot endpoint that produces fail2ban events from repeated failed login attempts.

## Runtime model

- The container runs upstream `freeradius` on port `1812/udp`.
- Authentication attempts are logged to `/var/log/radius/radius.log`.
- The log file is mounted via a shared volume and consumed by fail2ban.
- fail2ban uses the upstream `freeradius` filter.

## Credentials policy

- No static password is stored in the repository.
- A random runtime password and RADIUS client secret are generated on every container start.
- Current runtime credentials are written to `/run/hacktrap/radius_credentials.env` inside the container.

## Paths

- Build: `build/radius/`
- Config: `etc/radius/`
- Service defaults: `config/services.env`
- Test: `tests/radius/test_fail2ban_scope.sh`
- fail2ban jail: `fail2ban/radius/jail.local`
