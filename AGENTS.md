# AGENTS.md

## Project overview

HackTrapAgent is a containerised honeypot suite built on Docker Compose. It simulates vulnerable network services inside Docker containers and uses `fail2ban` to detect intrusion attempts.

Current baseline is SSH + fail2ban with service-oriented folders and tests.

## Cursor Cloud specific instructions

### Prerequisites available in the VM

- **Docker Engine 28.x** and **Docker Compose v5.x** (plugin) are installed.
- **Git** is available.

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

## Repository conventions (mandatory)

1. **No static passwords in repository.**
   - Service passwords must be generated at container startup.
   - Do not hardcode defaults like `123456`, `admin`, `trap123`, etc.

2. **Tests are service-scoped.**
   - Add tests under `tests/<service>/...`.
   - CI should run tests per service (matrix/parallel jobs).

3. **`README.md` is user-facing only.**
   - Developer and advanced setup docs must be in separate files (e.g. `docs/development/README.md`, `docs/advanced/README.md`).

4. **Large technical details go to dedicated docs.**
   - For service-specific implementation notes, create files like `docs/services/<service>.md` and link them from main docs.

5. **Use explicit service-oriented structure.**
   - `build/<service>/`
   - `etc/<service>/`
   - `fail2ban/<service>/`
   - `tests/<service>/`
   - `docs/services/<service>.md`

6. **Language policy (temporary).**
   - All repository Markdown files (`*.md`) must be written in English.
   - When communicating with the user in chat, respond in Russian.
   - For pull request or issue discussions, use the language in which the question/request was asked.
   - If a discussion is mixed-language, default to English.
