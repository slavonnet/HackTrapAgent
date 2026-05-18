# OpenVPN service implementation details

## Purpose

The OpenVPN service acts as an additional UDP-based honeypot signal source for fail2ban.

## Runtime model

- The container runs a lightweight UDP listener on port `1194`.
- Incoming probes are logged as OpenVPN-style authentication failures to `/var/log/openvpn/openvpn.log`.
- This log file is mounted via a shared volume and read by fail2ban.

## Credentials policy

- No static password is stored in the repository.
- A random runtime credential pair is generated each time the container starts.
- Current runtime credentials are written to `/run/hacktrap/openvpn_credentials.env` inside the container.

## Paths

- Build: `build/openvpn/`
- Config: `etc/openvpn/`
- Service defaults: `config/services.env`
- Test: `tests/openvpn/test_fail2ban_scope.sh`
- fail2ban jail: `fail2ban/openvpn/jail.local`
