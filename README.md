# HackTrapAgent

## Description

HackTrapAgent is a Docker Compose honeypot suite with service-specific containers and `fail2ban`-based local banning logic.

- Service enablement and default public ports are managed from one source: `config/services.env`.
- Public ports are set to service-standard values in the default configuration.
- Startup flow automatically resolves runtime port collisions by switching to alternative ports or disabling conflicting services.

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

The table below is based on the 5-minute benchmark format (`Port`, service docs link, image size, peak memory, CPU time).  
Peak memory can be `n/a` when Docker memory accounting is unavailable on the host.
Because L2TP and IKEv2 share default UDP ports `500` and `4500`, runtime conflict resolver keeps L2TP on defaults and moves IKEv2 to free alternatives.

| Port | Service (docs) | Image size | Peak memory | CPU time (core-seconds) |
| --- | --- | --- | --- | --- |
| 5060/tcp, 5060/udp, 4569/udp, 5038/tcp, 8088/tcp | [asterisk](docs/services/asterisk.md) | 238.34 MiB | n/a | 1.19 |
| 22/tcp | [ssh](docs/services/ssh.md) | 93.69 MiB | n/a | 0.54 |
| 23/tcp | [telnetd](docs/services/telnetd.md) | 129.96 MiB | n/a | 0.54 |
| 21/tcp | [ftp](docs/services/ftp.md) | 83.86 MiB | n/a | 0.53 |
| 123/udp | [ntp](docs/services/ntp.md) | 118.05 MiB | n/a | 0.48 |
| 2049/tcp | [nfs](docs/services/nfs.md) | 123.87 MiB | n/a | 0.53 |
| 5432/tcp | [postgresql](docs/services/postgresql.md) | 406.11 MiB | n/a | 1.38 |
| 3306/tcp | [mysql](docs/services/mysql.md) | 430.07 MiB | n/a | 0.56 |
| 11211/tcp | [memcached](docs/services/memcached.md) | 163.42 MiB | n/a | 0.24 |
| 27017/tcp | [mongodb](docs/services/mongodb.md) | 905.25 MiB | n/a | 1.99 |
| 6379/tcp | [redis](docs/services/redis.md) | 86.04 MiB | n/a | 1.50 |
| 179/tcp | [bgp](docs/services/bgp.md) | 109.42 MiB | n/a | 0.54 |
| 1194/udp | [openvpn](docs/services/openvpn.md) | 88.16 MiB | n/a | 0.55 |
| 445/tcp | [smb](docs/services/smb.md) | 225.86 MiB | n/a | 0.50 |
| 9092/tcp | [kafka](docs/services/kafka.md) | 88.16 MiB | n/a | 0.52 |
| 1701/udp, 500/udp, 4500/udp | [l2tp](docs/services/l2tp.md) | 93.29 MiB | n/a | 0.51 |
| 10500/udp, 14500/udp | [ike2](docs/services/ike2.md) | 92.80 MiB | n/a | 0.51 |
| 143/tcp | [imap](docs/services/imap.md) | 131.15 MiB | n/a | 0.54 |
| 110/tcp | [pop3](docs/services/pop3.md) | 130.66 MiB | n/a | 0.52 |
| 25/tcp | [smtp](docs/services/smtp.md) | 169.55 MiB | n/a | 0.52 |
| 9200/tcp | [elasticsearch](docs/services/elasticsearch.md) | 116.99 MiB | n/a | 1.01 |
| 8123/tcp, 9000/tcp | [clickhouse](docs/services/clickhouse.md) | 583.92 MiB | n/a | 4.88 |
| 389/tcp | [ad](docs/services/ad.md) | 135.98 MiB | n/a | 0.46 |
| 1812/udp | [radius](docs/services/radius.md) | 137.81 MiB | n/a | 0.51 |
| 5672/tcp, 15672/tcp | [rabbitmq](docs/services/rabbitmq.md) | 238.80 MiB | n/a | 19.89 |
| 3389/tcp | [rdp](docs/services/rdp.md) | 88.91 MiB | n/a | 0.52 |
| 161/udp | [snmp](docs/services/snmp.md) | 135.89 MiB | n/a | 0.53 |
| 162/udp | [snmptrap](docs/services/snmptrap.md) | 136.58 MiB | n/a | 0.52 |

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
