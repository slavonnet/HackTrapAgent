# IKEv2 service implementation details

## Purpose

The IKEv2 service acts as an IPsec-related UDP honeypot signal source for fail2ban.

## Runtime model

- The container runs two UDP listeners using `socat`:
  - `500/udp` (IKE)
  - `4500/udp` (NAT-T)
- Incoming packets are logged as failed IKEv2 authentication events in `/var/log/ike2/ike2.log`.
- The log file is mounted via a shared volume and read by fail2ban.

## Credentials policy

- No static password is stored in the repository.
- New random passwords are generated on every container start for `root` and the service user.
- A random runtime pre-shared key is generated on startup.
- Current runtime credentials are written to `/run/hacktrap/ike2_credentials.env` inside the container.

## Paths

- Build: `build/ike2/`
- Config: `etc/ike2/`
- Service defaults: `config/services.env`
- Test: `tests/ike2/test_fail2ban_scope.sh`
- fail2ban jail/filter: `fail2ban/ike2/`
