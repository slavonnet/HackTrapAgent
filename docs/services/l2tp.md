# L2TP service implementation details

## Purpose

The L2TP service acts as a UDP honeypot signal source for fail2ban.

## Runtime model

- The container runs a lightweight UDP listener on port `1701` using `socat`.
- Each incoming packet is logged as a failed L2TP authentication event in `/var/log/l2tp/l2tp.log`.
- The log file is mounted via a shared volume and read by fail2ban.

## Credentials policy

- No static password is stored in the repository.
- New random passwords are generated on every container start for `root` and the service user.
- A random runtime pre-shared key is generated on startup.
- Current runtime credentials are written to `/run/hacktrap/l2tp_credentials.env` inside the container.

## Paths

- Build: `build/l2tp/`
- Config: `etc/l2tp/`
- Service defaults: `config/services.env`
- Test: `tests/l2tp/test_fail2ban_scope.sh`
- fail2ban jail/filter: `fail2ban/l2tp/`
