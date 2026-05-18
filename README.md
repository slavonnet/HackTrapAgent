# HackTrapAgent

A lightweight Docker Compose honeypot for collecting attacker IP addresses and forwarding security signals to an external system.

## Current capabilities

- Starts an SSH honeypot (`localhost:2222`).
- Starts an FTP honeypot (`localhost:2121`).
- Starts a MySQL honeypot (`localhost:3306`).
- `fail2ban` monitors failed auth attempts and records attacker IPs.
- Temporary local bans are applied only inside the fail2ban container scope (host firewall is untouched).
- Runtime service defaults come from one source: `config/services.env`.

## Quick start

```bash
./scripts/compose_up.sh
```

Check status:

```bash
docker compose ps
docker compose logs -f fail2ban ssh ftp mysql
```

Stop:

```bash
./scripts/compose_down.sh
```

## Project structure

- `build/<service>/` — service Dockerfile and runtime entrypoint.
- `etc/<service>/` — service runtime configuration.
- `fail2ban/<service>/` — fail2ban jail for a specific service.
- `tests/<service>/` — service-specific integration tests.
- `docs/services/<service>.md` — implementation details for a specific service.
- `config/services.env` — one source of truth for enabled services and ports.

## Additional documentation

- Development and local testing: `docs/development/README.md`
- Advanced configuration: `docs/advanced/README.md`
- SSH service implementation: `docs/services/ssh.md`
- FTP service implementation: `docs/services/ftp.md`
- MySQL service implementation: `docs/services/mysql.md`
- Roadmap: `docs/ROADMAP.md`

## License

MIT
