# L2TP service implementation details

## Purpose

The L2TP service provides a real L2TP/IPsec stack and produces fail2ban signals from real strongSwan authentication failures.

## Runtime model

- The container runs `strongSwan` for IPsec (IKEv1 transport profile for L2TP/IPsec) and `xl2tpd` for L2TP.
- IPsec endpoints are active on `500/udp` and `4500/udp`, and L2TP is active on `1701/udp`.
- strongSwan writes real negotiation/authentication logs to `/var/log/l2tp/charon.log`.
- The log file is mounted via a shared volume and read by fail2ban.

## Credentials policy

- No static password is stored in the repository.
- A random runtime password is generated on every start for the service user.
- A random runtime pre-shared key is generated on startup.
- Current runtime credentials are written to `/run/hacktrap/l2tp_credentials.env` inside the container.

## Paths

- Build: `build/l2tp/`
- Config: `etc/l2tp/`
- Service defaults: `config/services.env`
- Test: `tests/l2tp/test_fail2ban_scope.sh`
- fail2ban jail/filter: `fail2ban/l2tp/`
