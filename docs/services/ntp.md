# NTP service implementation details

## Purpose

The NTP service acts as a UDP-based honeypot signal source for fail2ban.

## Runtime model

- The container runs real `ntpd` (`ntpsec`) on port `123/udp`.
- `ntpd` runs in foreground debug mode and writes native daemon packet traces to `/var/log/ntp/ntp.log`.
- This log file is mounted via a shared volume and consumed by fail2ban.

## Anonymous access policy

- Anonymous control and management queries are restricted via `restrict ... noquery` policy in `etc/ntp/ntp.conf`.
- The honeypot keeps packet visibility for suspicious mode 6/7 probe attempts in daemon logs.

## Filter strategy

- The jail uses an `ntpd` filter that matches native `read_network_packet ... from <HOST>` daemon traces.
- Filter file: `fail2ban/ntp/filter.d/ntpd.conf`.

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
- fail2ban filter: `fail2ban/ntp/filter.d/ntpd.conf`
