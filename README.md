# HackTrapAgent

## Description

HackTrapAgent is a Docker Compose honeypot suite with service-specific containers and `fail2ban`-based local banning logic.

- Service enablement and default public ports are managed from one source: `config/services.env`.
- Public ports are set to service-standard values in the default configuration.
- Startup flow automatically resolves runtime port collisions by switching to alternative ports or disabling conflicting services.
- Container healthchecks are disabled; each honeypot container self-terminates every 1800 seconds and is relaunched by Docker restart policy to reset compromised state.
- Service-level documentation is maintained under `docs/services/` (including `tftp`).

## Install & Quick start

1. Install required packages:

   ```bash
   sudo apt-get update
   sudo apt-get install -y docker.io docker-compose-plugin python3
   ```

2. Run setup + build + startup:

   ```bash
   ./scripts/compose_up.sh
   ```

   What this script does:
   - prepares a runtime env (`/tmp/hacktrapagent-services.runtime.env`);
   - checks host port conflicts and service-to-service overlaps;
   - moves conflicting ports to free alternatives or disables unresolved services;
   - builds images and starts `fail2ban` plus enabled service containers.

3. Check status:

   ```bash
   sudo docker compose --env-file /tmp/hacktrapagent-services.runtime.env -f docker-compose.yml ps
   ```

4. Stop and cleanup:

   ```bash
   ./scripts/compose_down.sh
   ```

## Services containers

The table below is based on the 5-minute benchmark format (`Port`, service docs link, `Image size (MiB)`, `Peak memory (MiB)`, CPU time), includes `fail2ban` (without public port), and has a `TOTAL` block with aggregate metrics.
Peak memory can still be `n/a` when Docker memory accounting is unavailable on the host.

| Port | Service (docs) | Image size (MiB) | Peak memory (MiB) | CPU time (core-seconds) |
| --- | --- | --- | --- | --- |
| - | fail2ban | 125 | 21 | 0.80 |
| 5060/tcp, 5060/udp, 4569/udp, 5038/tcp, 8088/tcp | [asterisk](docs/services/asterisk.md) | 238 | 50 | 0.65 |
| 22/tcp | [ssh](docs/services/ssh.md) | 94 | 10 | 0.00 |
| 23/tcp | [telnetd](docs/services/telnetd.md) | 130 | 9 | 0.00 |
| 21/tcp | [ftp](docs/services/ftp.md) | 84 | 9 | 0.00 |
| 2069/udp | [tftp](docs/services/tftp.md) | 84 | 3 | 0.00 |
| 123/udp | [ntp](docs/services/ntp.md) | 118 | 5 | 0.00 |
| 2049/tcp | [nfs](docs/services/nfs.md) | 124 | 6 | 0.00 |
| 5432/tcp | [postgresql](docs/services/postgresql.md) | 406 | 50 | 0.06 |
| 3306/tcp | [mysql](docs/services/mysql.md) | 430 | 102 | 0.01 |
| 11211/tcp | [memcached](docs/services/memcached.md) | 163 | 15 | 0.01 |
| 27017/tcp | [mongodb](docs/services/mongodb.md) | 905 | 301 | 0.63 |
| 6379/tcp | [redis](docs/services/redis.md) | 86 | 12 | 0.84 |
| 179/tcp | [bgp](docs/services/bgp.md) | 109 | 11 | 0.00 |
| 1194/udp | [openvpn](docs/services/openvpn.md) | 88 | 4 | 0.00 |
| 445/tcp | [smb](docs/services/smb.md) | 226 | 27 | 0.00 |
| 9092/tcp | [kafka](docs/services/kafka.md) | 88 | 4 | 0.00 |
| 1701/udp, 500/udp, 4500/udp | [ipsec](docs/services/ipsec.md) | 94 | 14 | 0.00 |
| 143/tcp | [imap](docs/services/imap.md) | 131 | 11 | 0.00 |
| 110/tcp | [pop3](docs/services/pop3.md) | 131 | 11 | 0.00 |
| 25/tcp | [smtp](docs/services/smtp.md) | 170 | 18 | 0.00 |
| 9200/tcp | [elasticsearch](docs/services/elasticsearch.md) | 117 | 12 | 0.01 |
| 8123/tcp, 9000/tcp | [clickhouse](docs/services/clickhouse.md) | 584 | 351 | 4.15 |
| 389/tcp | [ad](docs/services/ad.md) | 136 | 16 | 0.00 |
| 1812/udp | [radius](docs/services/radius.md) | 138 | 86 | 0.00 |
| 5672/tcp, 15672/tcp | [rabbitmq](docs/services/rabbitmq.md) | 239 | 122 | 2.63 |
| 3389/tcp | [rdp](docs/services/rdp.md) | 89 | 10 | 0.00 |
| 161/udp | [snmp](docs/services/snmp.md) | 136 | 11 | 0.02 |
| 162/udp | [snmptrap](docs/services/snmptrap.md) | 137 | 9 | 0.00 |

**TOTAL**

- Total image size: 6 GB (5 GiB)
- Total CPU time (core-seconds): 9.82
- Group peak memory: 1 GB (1 GiB)

## Targets

- `iptables` target: [docs/targets/iptables.md](docs/targets/iptables.md)
- `AbuseIPDB` target: planned
- `Webhook` target: planned

## Advanced

- [Advanced configuration](docs/advanced/README.md)
- [Service-level implementation notes](docs/services)

## Developer Docs

- [Development guide](docs/development/README.md)
- [Tests guide](tests/README.md)

## Road Map

- [Project roadmap](docs/ROADMAP.md)

## License

- [MIT](LICENSE)
