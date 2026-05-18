# HackTrapAgent

A lightweight Docker Compose honeypot for collecting attacker IP addresses and automatically blocking them in the container scope.

## Current capabilities

- Starts an SSH honeypot (`localhost:2222`).
- `fail2ban` monitors failed auth attempts and bans attacker IPs.
- The ban is applied only in the service container network namespace (not on the host).

## Quick start

```bash
docker compose up -d --build ssh fail2ban
```

Check status:

```bash
docker compose ps
docker compose logs -f fail2ban ssh
```

Stop:

```bash
docker compose down -v
```

## Project structure

- `build/<service>/` — service Dockerfile and runtime entrypoint.
- `etc/<service>/` — service runtime configuration.
- `fail2ban/<service>/` — fail2ban jail for a specific service.
- `tests/<service>/` — service-specific integration tests.
- `docs/services/<service>.md` — implementation details for a specific service.

## Additional documentation

- Development and local testing: `docs/development/README.md`
- Advanced configuration: `docs/advanced/README.md`
- SSH service implementation: `docs/services/ssh.md`

## License

MIT
