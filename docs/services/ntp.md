# NTP service implementation details

## Purpose

The NTP service acts as a UDP-based honeypot signal source for fail2ban.

## Runtime model

- The container runs a lightweight Python UDP listener on port `123`.
- Incoming datagrams are logged to `/var/log/ntp/ntp.log`.
- This log file is mounted via a shared volume and consumed by fail2ban.
- The service intentionally does not provide valid NTP responses, so probes are treated as suspicious traffic events.

## Credentials policy

- NTP service does not use authentication credentials.
- No static passwords or secrets are stored for this service.

## Paths

- Build: `build/ntp/`
- Config: `etc/ntp/`
- Service defaults: `config/services.env`
- Test: `tests/ntp/test_fail2ban_scope.sh`
- fail2ban jail: `fail2ban/ntp/jail.local`
- fail2ban filter: `fail2ban/ntp/filter.d/ntp-honeypot.conf`
