# Testing

## Goal

Validate that:

1. Failed SSH brute-force attempts trigger a ban in `fail2ban`.
2. The ban is applied only in container network namespace (not on host).

## Local run

Prerequisites:

- Docker Engine with `docker compose`
- Access to host `iptables` (directly or via passwordless `sudo`)

Command:

```bash
chmod +x tests/test_fail2ban_container_scope.sh
./tests/test_fail2ban_container_scope.sh
```

Expected output:

```text
PASS: fail2ban bans attacker IP in container namespace only (<ip>)
```
