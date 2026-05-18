# TFTP service implementation details

## Purpose

The TFTP service provides a UDP-based honeypot signal source for suspicious file transfer activity.

## Runtime model

- The container runs real `in.tftpd` (`tftpd-hpa`) on port `69/udp`.
- The service root is `/srv/tftp`, exposed in secure mode.
- Daemon output is persisted to `/var/log/tftp/tftpd.log`.
- This log file is mounted via a shared volume and consumed by fail2ban.

## Anonymous access policy

- TFTP protocol does not provide authentication primitives.
- To avoid unauthenticated write capability, the TFTP root is intentionally read-only.
- Repeated write requests (`WRQ`) are still accepted at protocol level and logged as attack signals.

## Filter strategy

- No maintained upstream fail2ban filter is currently available for this TFTP daemon log format.
- A service-local filter matches repeated `WRQ from <HOST>` events.
- Filter file: `fail2ban/tftp/filter.conf`.

## Credentials policy

- TFTP service does not use authentication credentials.
- No static passwords or secrets are stored for this service.

## Traffic safety scope

- Test traffic for this service is restricted to local Docker Compose lab targets only.
- The service and tests are not intended for generating external attack traffic.

## Paths

- Build: `build/tftp/`
- Config: `etc/tftp/`
- Service defaults: `config/services.env`
- Test: `tests/tftp/test_fail2ban_scope.sh`
- fail2ban jail: `fail2ban/tftp/jail.local`
- fail2ban filter: `fail2ban/tftp/filter.conf`
