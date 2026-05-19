# IPsec service implementation details

## Purpose

The IPsec service combines L2TP/IPsec (IKEv1) and IKEv2/EAP profiles in one container and produces fail2ban signals from real strongSwan authentication failures.

## Runtime model

- The container runs `strongSwan` for both L2TP and IKEv2 profiles.
- Optional L2TP daemon `xl2tpd` runs in the same container and serves `1701/udp`.
- IPsec endpoints are active on `500/udp` and `4500/udp`.
- Both modes are controlled by runtime settings:
  - `IPSEC_ENABLE_L2TP=true|false`
  - `IPSEC_ENABLE_IKEV2=true|false`
- strongSwan writes negotiation/authentication logs to `/var/log/ipsec/charon.log`.
- The log file is mounted via a shared volume and read by fail2ban.

## Credentials policy

- No static passwords are stored in the repository.
- A random runtime password is generated on every start for service users.
- A random runtime pre-shared key is generated on startup for L2TP mode.
- Runtime CA and server certificates are generated on startup for IKEv2 mode.
- Current runtime credentials are written to `/run/hacktrap/ipsec_credentials.env` inside the container.

## Paths

- Build: `build/ipsec/`
- Config: `etc/ipsec/`
- Service defaults: `config/services.env`
- Test: `tests/ipsec/test_fail2ban_scope.sh`
- fail2ban jail/filter: `fail2ban/ipsec/`
