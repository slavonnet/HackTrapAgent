# Roadmap

## Phase 1 — Core infrastructure

- [x] Docker Compose baseline with `fail2ban` container
- [x] SSH jail configuration
- [x] Shared volume-based log flow between service and `fail2ban`
- [x] Integration test for container-scope ban behavior
- [ ] Add baseline jails for other services (FTP, SIP, etc.)

## Phase 2 — Transport modules

- [ ] Syslog forwarder (RFC 3164)
- [ ] Webhook forwarder (HTTP POST)
- [ ] Custom fail2ban actions for remote blacklisting systems
- [ ] MQ publisher (RabbitMQ / MQTT)

## Phase 3 — Service expansion

For each service, provide:

- [ ] Service Dockerfile and runtime config
- [ ] Dedicated log file in shared volume
- [ ] Service-specific integration test
- [ ] Service implementation note under `docs/services/<service>.md`

Priority candidates:

- [x] `ftp`
- [x] `ntp`
- [x] `smtp`
- [x] `imap`
- [x] `pop3`
- [x] `bgp`
- [ ] `sip`
- [ ] `iax`
- [ ] `dns`
- [ ] `snmp`
- [x] `mysql`
- [x] `postgresql`
- [x] `elasticsearch`
- [x] `l2tp`
- [x] `ipsec` (IKEv2)
- [x] `openvpn`

## Phase 4 — Production hardening

- [ ] Support multiple backend targets
- [ ] Healthchecks and auto-restart strategy for all services
- [ ] Metrics and observability
