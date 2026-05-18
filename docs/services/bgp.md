# BGP service implementation details

## Purpose

The BGP service acts as a lightweight honeypot endpoint that records connection attempts from unconfigured peers.

## Runtime model

- The container runs a small TCP listener on port `179`.
- Every incoming connection is checked against the configured peer list.
- Unconfigured peer attempts are logged to `/var/log/bgp/bgp.log`.
- The log file is mounted via shared volume and consumed by fail2ban.

## Peer configuration

- Configured peers can be provided via:
  - `etc/bgp/peers.conf`
  - `BGP_ALLOWED_PEERS` in `config/services.env`
- All peer entries must be valid IP addresses.

## Paths

- Build: `build/bgp/`
- Config: `etc/bgp/`
- Service defaults: `config/services.env`
- Test: `tests/bgp/test_fail2ban_scope.sh`
- fail2ban jail: `fail2ban/bgp/jail.local`
