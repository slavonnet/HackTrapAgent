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
| - | fail2ban | 125 | 38 | 2.78 |
| 5060/tcp, 5060/udp, 4569/udp, 5038/tcp, 8088/tcp | [asterisk](docs/services/asterisk.md) | 238 | 59 | 1.33 |
| 22/tcp | [ssh](docs/services/ssh.md) | 94 | 13 | 0.52 |
| 23/tcp | [telnetd](docs/services/telnetd.md) | 130 | 11 | 0.63 |
| 21/tcp | [ftp](docs/services/ftp.md) | 84 | 11 | 0.55 |
| 2069/udp | [tftp](docs/services/tftp.md) | 84 | 6 | 0.52 |
| 123/udp | [ntp](docs/services/ntp.md) | 118 | 8 | 0.55 |
| 2049/tcp | [nfs](docs/services/nfs.md) | 124 | 7 | 0.54 |
| 5432/tcp | [postgresql](docs/services/postgresql.md) | 406 | 54 | 1.38 |
| 3306/tcp | [mysql](docs/services/mysql.md) | 430 | 104 | 0.55 |
| 11211/tcp | [memcached](docs/services/memcached.md) | 163 | 19 | 0.22 |
| 27017/tcp | [mongodb](docs/services/mongodb.md) | 905 | 303 | 1.98 |
| 6379/tcp | [redis](docs/services/redis.md) | 86 | 13 | 1.55 |
| 179/tcp | [bgp](docs/services/bgp.md) | 109 | 13 | 0.58 |
| 1194/udp | [openvpn](docs/services/openvpn.md) | 88 | 6 | 0.56 |
| 445/tcp | [smb](docs/services/smb.md) | 226 | 28 | 0.54 |
| 9092/tcp | [kafka](docs/services/kafka.md) | 88 | 6 | 0.58 |
| 1701/udp, 500/udp, 4500/udp | [ipsec](docs/services/ipsec.md) | 93 | 13 | 0.58 |
| 143/tcp | [imap](docs/services/imap.md) | 131 | 12 | 0.57 |
| 110/tcp | [pop3](docs/services/pop3.md) | 131 | 13 | 0.55 |
| 25/tcp | [smtp](docs/services/smtp.md) | 170 | 19 | 0.53 |
| 9200/tcp | [elasticsearch](docs/services/elasticsearch.md) | 117 | 21 | 1.07 |
| 8123/tcp, 9000/tcp | [clickhouse](docs/services/clickhouse.md) | 584 | 348 | 5.26 |
| 389/tcp | [ad](docs/services/ad.md) | 136 | 18 | 0.48 |
| 1812/udp | [radius](docs/services/radius.md) | 138 | 87 | 0.54 |
| 5672/tcp, 15672/tcp | [rabbitmq](docs/services/rabbitmq.md) | 239 | 121 | 3.40 |
| 3389/tcp | [rdp](docs/services/rdp.md) | 89 | 14 | 0.55 |
| 161/udp | [snmp](docs/services/snmp.md) | 136 | 14 | 0.58 |
| 162/udp | [snmptrap](docs/services/snmptrap.md) | 137 | 13 | 0.55 |

**TOTAL**

- Total image size: 6 GB (6 GiB)
- Total CPU time (core-seconds): 30.52
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
