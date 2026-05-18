# HackTrapAgent

**Lightweight Docker Compose honeypot that catches hackers and feeds their IPs to the main host for blacklisting.**

## Description

HackTrapAgent is a containerised honeypot suite designed to lure attackers and automatically capture their IP addresses. It runs a set of vulnerable‑looking services (SSH, FTP, SIP, etc.) inside Docker containers and uses `fail2ban` to monitor their logs. When an intrusion attempt is detected, the offending IP is extracted and forwarded to a remote main host via multiple transport methods (syslog, webhook, fail2ban actions, MQ). The main host can then instantly add the IP to a blacklist (e.g., iptables, cloud firewall).

Unlike typical setups, HackTrapAgent makes `fail2ban` read service logs **directly from files**, not through syslog. This avoids log loss and reduces complexity.

## Architecture (Containers)

The project consists of two types of containers:

1. **Service containers** – simulate real network services to attract attackers.  
   Planned and supported services:

   - `ssh`
   - `sip`
   - `ftp`
   - `iax`
   - `dns`
   - `snmp`
   - `imap`
   - `mysql`
   - `postgresql`
   - `l2tp`
   - `ipsec`
   - `openvpn`
   - more to come…

2. **Core container** – runs `fail2ban` and transport modules.  
   - `fail2ban` reads log files written by service containers (mounted volumes).  
   - When a ban is triggered, IPs are passed to one or more transport modules.

**Transport modules** (currently planned):
- `syslog` – forward IPs to a remote syslog server
- `web-hook` – send JSON over HTTP to a REST endpoint
- `fail2ban actions` – invoke custom scripts (e.g., `iptables`, `ipset` on the main host)
- `MQ` – push to a message queue (RabbitMQ / MQTT)

All containers are orchestrated with **Docker Compose**.

## Installation & Setup

### Prerequisites
- Linux host (Ubuntu/Debian recommended)
- Docker & Docker Compose installed
- Git

### Quick start

In development

## Roadmap

### Phase 1 – Core infrastructure
- [ ] Docker Compose skeleton with `fail2ban` container
- [ ] Write `fail2ban` jails for each service (SSH, FTP, …)
- [ ] Implement volume‑based log sharing between services and `fail2ban`
- [ ] Test direct log reading (no syslog)

### Phase 2 – Transport modules
- [ ] syslog forwarder (RFC 3164)
- [ ] Web‑hook forwarder (HTTP POST)
- [ ] Custom fail2ban action scripts (for remote blacklisting)
- [ ] MQTT / RabbitMQ publisher

### Phase 3 – Service containers to be documented and configured
For each service, we need to provide a Dockerfile + configuration that:
- [ ] Runs the service in a realistic (but fake) way
- [ ] Writes logs to a dedicated file inside a shared volume
- [ ] Listens on a configurable port

**Priority list:**
- [ ] `ssh` (high‑interaction mock or modified OpenSSH)
- [ ] `ftp` (vsftpd or pyftpdlib with logging)
- [ ] `sip` (asterisk or opensips with authentication failures)
- [ ] `iax` (Asterisk IAX2 module)
- [ ] `dns` (fake DNS server logging ANY queries)
- [ ] `snmp` (snmpd with public community, log failed auth)
- [ ] `imap` (Dovecot with plain auth, log failures)
- [ ] `mysql` & `postgresql` (log invalid logins)
- [ ] `l2tp` / `ipsec` (strongSwan with failure logging)
- [ ] `openvpn` (log invalid certificates or auth)

### Phase 4 – Production hardening
- [ ] Support for multiple backend targets (load balancing)
- [ ] Healthchecks and auto‑restart policies
- [ ] Prometheus metrics for number of banned IPs

## Features

- **Direct log reading by fail2ban** – All service containers write logs to plain files in bind‑mounted volumes. `fail2ban` reads these files **directly** using its native backend (`polling` or `pyinotify`). No syslog daemon required inside the honeypot.
- **Multi‑transport forwarding** – Send captured IPs to the main host via syslog, HTTP webhook, MQ, or custom fail2ban actions.
- **Low overhead** – Containers share resources, easy to spin up/down.
- **Extensible** – Add your own service container or transport module by following the volume and logging convention.

## License

MIT
