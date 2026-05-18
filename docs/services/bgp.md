# BGP service implementation details

## Purpose

The BGP service runs a real BGP daemon (`bgpd`) from FRRouting (successor of Quagga) and logs peer connection activity for fail2ban.

## Runtime model

- The container starts `bgpd` on TCP port `179`.
- Startup renders `/etc/frr/bgpd.conf` from `etc/bgp/peers.conf` plus `BGP_ALLOWED_PEERS`.
- `bgpd` writes detailed events to `/var/log/bgp/bgp.log`.
- fail2ban monitors that log and bans repeated unconfigured peer attempts.

## Peer configuration

- Configured peers can be provided by:
  - `etc/bgp/peers.conf`
  - `BGP_ALLOWED_PEERS` in `config/services.env`
- Peer tokens must be valid IPv4 addresses.
- `BGP_LOCAL_ASN`, `BGP_PEER_ASN`, and `BGP_ROUTER_ID` are configurable in `config/services.env`.

## Paths

- Build: `build/bgp/`
- Config: `etc/bgp/`
- Service defaults: `config/services.env`
- Test: `tests/bgp/test_fail2ban_scope.sh`
- fail2ban jail: `fail2ban/bgp/jail.local`
