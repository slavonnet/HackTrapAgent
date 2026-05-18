# NTP service implementation details

## Purpose

The NTP service acts as a UDP-based honeypot signal source for fail2ban.

## Runtime model

- The container runs a lightweight Python UDP listener on port `123`.
- Incoming datagrams are decoded and logged as explicit request actions
  (for example: mode 6 control requests, mode 7 private requests, malformed packets).
- Action logs are written to `/var/log/ntp/ntp.log`.
- This log file is mounted via a shared volume and consumed by fail2ban.
- The service intentionally does not provide valid NTP responses, so probes are treated as suspicious traffic events.

## Anonymous access policy

- The service does not grant anonymous access to NTP actions.
- Unauthenticated packets are explicitly denied and logged as `unauth-denied-*` events.

## Filter strategy

- The project reuses fail2ban's standard NTP-related parsing conventions where possible (mode-oriented request semantics).
- A dedicated upstream filter for this synthetic honeypot log format is not shipped by fail2ban, so the repository keeps a minimal custom filter at `fail2ban/ntp/filter.d/ntp-honeypot.conf`.

## Credentials policy

- NTP service does not use authentication credentials.
- No static passwords or secrets are stored for this service.

## Traffic safety scope

- Test traffic for this service is restricted to local Docker Compose lab targets only.
- The service and tests are not intended for generating external attack or stress traffic.

## Paths

- Build: `build/ntp/`
- Config: `etc/ntp/`
- Service defaults: `config/services.env`
- Test: `tests/ntp/test_fail2ban_scope.sh`
- fail2ban jail: `fail2ban/ntp/jail.local`
- fail2ban filter: `fail2ban/ntp/filter.d/ntp-honeypot.conf`
