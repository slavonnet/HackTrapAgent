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

The table below is based on the 5-minute benchmark format (`Port`, service docs link, image size, peak memory, CPU time), includes `fail2ban` (without public port), and has a `TOTAL` block with aggregate metrics.
Peak memory can still be `n/a` when Docker memory accounting is unavailable on the host.

| Port | Service (docs) | Image size | Peak memory | CPU time (core-seconds) |
| --- | --- | --- | --- | --- |
| - | fail2ban | 125.43 MiB | 39.18 MiB | 2.84 |
| 5060/tcp, 5060/udp, 4569/udp, 5038/tcp, 8088/tcp | [asterisk](docs/services/asterisk.md) | 238.34 MiB | 59.04 MiB | 1.29 |
| 22/tcp | [ssh](docs/services/ssh.md) | 93.69 MiB | 11.88 MiB | 0.54 |
| 23/tcp | [telnetd](docs/services/telnetd.md) | 129.96 MiB | 13.48 MiB | 0.65 |
| 21/tcp | [ftp](docs/services/ftp.md) | 83.86 MiB | 10.26 MiB | 0.54 |
| 2069/udp | [tftp](docs/services/tftp.md) | 84.48 MiB | 6.17 MiB | 0.52 |
| 123/udp | [ntp](docs/services/ntp.md) | 118.05 MiB | 7.71 MiB | 0.56 |
| 2049/tcp | [nfs](docs/services/nfs.md) | 123.87 MiB | 8.84 MiB | 0.55 |
| 5432/tcp | [postgresql](docs/services/postgresql.md) | 406.11 MiB | 53.17 MiB | 1.39 |
| 3306/tcp | [mysql](docs/services/mysql.md) | 430.07 MiB | 104.00 MiB | 0.57 |
| 11211/tcp | [memcached](docs/services/memcached.md) | 163.42 MiB | 15.65 MiB | 0.20 |
| 27017/tcp | [mongodb](docs/services/mongodb.md) | 905.25 MiB | 302.80 MiB | 1.83 |
| 6379/tcp | [redis](docs/services/redis.md) | 86.04 MiB | 13.93 MiB | 1.65 |
| 179/tcp | [bgp](docs/services/bgp.md) | 109.42 MiB | 13.16 MiB | 0.57 |
| 1194/udp | [openvpn](docs/services/openvpn.md) | 88.16 MiB | 5.56 MiB | 0.55 |
| 445/tcp | [smb](docs/services/smb.md) | 225.86 MiB | 29.79 MiB | 0.55 |
| 9092/tcp | [kafka](docs/services/kafka.md) | 88.16 MiB | 5.52 MiB | 0.53 |
| 1701/udp, 500/udp, 4500/udp | [ipsec](docs/services/ipsec.md) | 93.29 MiB | 12.76 MiB | 0.58 |
| 143/tcp | [imap](docs/services/imap.md) | 131.15 MiB | 14.66 MiB | 0.54 |
| 110/tcp | [pop3](docs/services/pop3.md) | 130.66 MiB | 14.00 MiB | 0.53 |
| 25/tcp | [smtp](docs/services/smtp.md) | 169.55 MiB | 19.38 MiB | 0.56 |
| 9200/tcp | [elasticsearch](docs/services/elasticsearch.md) | 116.99 MiB | 17.72 MiB | 1.06 |
| 8123/tcp, 9000/tcp | [clickhouse](docs/services/clickhouse.md) | 583.92 MiB | 343.70 MiB | 4.94 |
| 389/tcp | [ad](docs/services/ad.md) | 135.98 MiB | 18.55 MiB | 0.51 |
| 1812/udp | [radius](docs/services/radius.md) | 137.81 MiB | 88.32 MiB | 0.52 |
| 5672/tcp, 15672/tcp | [rabbitmq](docs/services/rabbitmq.md) | 238.80 MiB | 199.30 MiB | 19.99 |
| 3389/tcp | [rdp](docs/services/rdp.md) | 88.91 MiB | 11.36 MiB | 0.54 |
| 161/udp | [snmp](docs/services/snmp.md) | 135.89 MiB | 14.23 MiB | 0.55 |
| 162/udp | [snmptrap](docs/services/snmptrap.md) | 136.58 MiB | 11.08 MiB | 0.53 |

**TOTAL**

- Total image size: 5.97 GB (5.56 GiB)
- Total CPU time (core-seconds): 46.69
- Group peak memory: 1.46 GB (1.36 GiB)

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
