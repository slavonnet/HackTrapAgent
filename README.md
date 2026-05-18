# HackTrapAgent

A lightweight Docker Compose honeypot for collecting attacker IP addresses and forwarding security signals to an external system.

## Current capabilities

- Starts an SSH honeypot (`localhost:2222`).
- Starts a Telnet honeypot (`localhost:2323`).
- Starts an FTP honeypot (`localhost:2121`).
- Starts a TFTP honeypot (`localhost:2069/udp`).
- Starts an NTP honeypot (`localhost:2123/udp`).
- Starts an NFS honeypot (`localhost:2049`).
- Starts an IMAP honeypot (`localhost:2143`).
- Starts a POP3 honeypot (`localhost:2110`).
- Starts an SMTP honeypot (`localhost:2525`).
- Starts an L2TP honeypot (`localhost:11701/udp`).
- Starts an IKEv2 honeypot (`localhost:1500/udp` and `localhost:14500/udp`).
- Starts a PostgreSQL honeypot (`localhost:5432`).
- Starts a MySQL honeypot (`localhost:3306`).
- Starts a Redis honeypot (`localhost:6379`).
- Starts an Elasticsearch honeypot (`localhost:9200`).
- Starts a BGP honeypot (`localhost:2179`) and logs unconfigured peer connection attempts.
- Starts an OpenVPN honeypot (`localhost:1194/udp`).
- Starts a RabbitMQ honeypot (`localhost:5672`, management API at `localhost:15672`).
- Starts a RADIUS honeypot (`localhost:1812/udp`).
- Starts an Active Directory-compatible LDAP honeypot (`localhost:2389`).
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
docker compose logs -f fail2ban ssh telnetd ftp tftp ntp nfs postgresql mysql redis elasticsearch bgp l2tp ike2 imap pop3 smtp openvpn radius ad rabbitmq
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
- Telnet service implementation: `docs/services/telnetd.md`
- FTP service implementation: `docs/services/ftp.md`
- TFTP service implementation: `docs/services/tftp.md`
- NTP service implementation: `docs/services/ntp.md`
- NFS service implementation: `docs/services/nfs.md`
- IMAP service implementation: `docs/services/imap.md`
- POP3 service implementation: `docs/services/pop3.md`
- SMTP service implementation: `docs/services/smtp.md`
- L2TP service implementation: `docs/services/l2tp.md`
- IKEv2 service implementation: `docs/services/ike2.md`
- PostgreSQL service implementation: `docs/services/postgresql.md`
- MySQL service implementation: `docs/services/mysql.md`
- Redis service implementation: `docs/services/redis.md`
- Elasticsearch service implementation: `docs/services/elasticsearch.md`
- BGP service implementation: `docs/services/bgp.md`
- OpenVPN service implementation: `docs/services/openvpn.md`
- RabbitMQ service implementation: `docs/services/rabbitmq.md`
- RADIUS service implementation: `docs/services/radius.md`
- AD service implementation: `docs/services/ad.md`
- Roadmap: `docs/ROADMAP.md`

## License

MIT
