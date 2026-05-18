# Asterisk service implementation details

## Purpose

The Asterisk service provides a VoIP honeypot endpoint with enabled IAX, PJSIP, AMI (Manager), and ARI interfaces that generate fail2ban events on repeated authentication failures.

## Runtime model

- The container runs upstream Ubuntu `asterisk` package in foreground mode.
- Runtime interfaces are exposed on:
  - PJSIP: `5060/tcp` and `5060/udp`
  - IAX: `4569/udp`
  - AMI (Manager): `5038/tcp`
  - ARI (HTTP): `8088/tcp`
- Failed and security-related events are written to `/var/log/asterisk/messages`.
- The log file is mounted via a shared volume and consumed by fail2ban.
- fail2ban uses the maintained upstream `asterisk` filter.

## Credentials policy

- No static password is stored in the repository.
- A random runtime password is generated for the configured user each time the container starts.
- Current runtime credentials are written to `/run/hacktrap/asterisk_credentials.env` inside the container.

## Paths

- Build: `build/asterisk/`
- Config: `etc/asterisk/`
- Service defaults: `config/services.env`
- Test: `tests/asterisk/test_fail2ban_scope.sh`
- fail2ban jail: `fail2ban/asterisk/jail.local`
