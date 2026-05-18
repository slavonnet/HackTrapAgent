# AGENTS.md

## Project overview

HackTrapAgent is a containerised honeypot suite built on Docker Compose. It simulates vulnerable network services (SSH, FTP, SIP, etc.) inside Docker containers and uses `fail2ban` to detect intrusion attempts. Captured IPs are forwarded to a remote host for blacklisting via syslog, webhook, fail2ban actions, or message queue transports.

The project is in early development — see `README.md` for the full architecture and roadmap.

## Cursor Cloud specific instructions

### Prerequisites available in the VM

- **Docker Engine 28.x** and **Docker Compose v5.x** (plugin) are installed.
- **Git** is available.
- There is no application code yet (only `README.md`). All roadmap phases are pending.

### Starting Docker in the Cloud Agent VM

The Docker daemon does **not** auto-start. You must start it manually before running any `docker` or `docker compose` commands:

```bash
sudo dockerd &> /tmp/dockerd.log &
sleep 3  # wait for daemon to initialise
```

### Docker-in-Docker caveats

This VM runs inside a Firecracker microVM. The following workarounds are already configured:

- **Storage driver**: `fuse-overlayfs` (set in `/etc/docker/daemon.json`).
- **iptables**: switched to `iptables-legacy` (nftables is not fully supported by the kernel).

If you upgrade Docker to v29+, you may need to disable the `containerd-snapshotter` feature for `fuse-overlayfs` to keep working.

### Development workflow

Since the project is Docker Compose-based, development follows this pattern:

1. Write / edit Dockerfiles and `docker-compose.yml`.
2. Build images: `sudo docker compose build`
3. Start services: `sudo docker compose up -d`
4. Check logs: `sudo docker compose logs -f <service>`
5. Tear down: `sudo docker compose down -v`

All `docker` commands require `sudo` (the Cloud Agent user is not in the `docker` group).
