# IKEv2 service implementation details

## Purpose

The IKEv2 service provides a real strongSwan IKEv2 responder and produces fail2ban signals from real certificate/EAP authentication failures.

## Runtime model

- The container runs `strongSwan` with an IKEv2 EAP profile.
- Runtime server CA and server certificate are generated on startup and loaded into strongSwan.
- IKE endpoints are active on `500/udp` and `4500/udp`.
- strongSwan writes real negotiation/authentication logs to `/var/log/ike2/charon.log`.
- The log file is mounted via a shared volume and read by fail2ban.

## Credentials policy

- No static password is stored in the repository.
- A random runtime EAP password is generated on startup for the service user.
- Runtime CA/server certificates are generated on startup.
- Current runtime credentials are written to `/run/hacktrap/ike2_credentials.env` inside the container.

## Paths

- Build: `build/ike2/`
- Config: `etc/ike2/`
- Service defaults: `config/services.env`
- Test: `tests/ike2/test_fail2ban_scope.sh`
- fail2ban jail/filter: `fail2ban/ike2/`
