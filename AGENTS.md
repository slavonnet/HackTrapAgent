# AGENTS.md

## Project overview

HackTrapAgent is a containerised honeypot suite built on Docker Compose. It simulates vulnerable network services inside Docker containers and uses `fail2ban` to detect intrusion attempts.

Current baseline is SSH + fail2ban with service-oriented folders and tests.

## Cursor Cloud specific instructions

### Prerequisites available in the VM

- **Docker Engine 28.x** and **Docker Compose v5.x** (plugin) are installed.
- **Git** is available.

### Starting Docker in the Cloud Agent VM

The update script handles Docker startup automatically. **Do NOT start dockerd manually** — the update script kills stale Docker processes, flushes iptables, fixes cgroups, and starts a fresh daemon.

If you need to restart Docker mid-session:

```bash
# SIGKILL — no graceful shutdown (graceful can hang 5+ min on zombie shims)
for pid in $(pgrep -x dockerd 2>/dev/null); do sudo kill -9 "$pid" 2>/dev/null || true; done
sleep 1
sudo rm -f /var/run/docker.pid /var/run/docker.sock
sudo dockerd &> /tmp/dockerd.log &
sleep 3
```

### Docker-in-Docker caveats

This VM runs inside a Firecracker microVM. The following workarounds are already configured:

- **Storage driver**: `fuse-overlayfs` (set in `/etc/docker/daemon.json`).
- **iptables**: switched to `iptables-legacy` (nftables is not fully supported by the kernel).

If you upgrade Docker to v29+, you may need to disable the `containerd-snapshotter` feature for `fuse-overlayfs` to keep working.

### Post-snapshot recovery (iptables + zombie processes)

**Do NOT manually patch iptables rules or try graceful Docker shutdown.** The update script handles this automatically.

After snapshot restore, Docker processes become broken: `containerd-shim` turns into zombies, stale `DOCKER-ISOLATION-STAGE-2` iptables chains block traffic, and `dockerd` holds lock files. The update script:

1. **SIGKILL** (not SIGTERM) all Docker processes — avoids 5+ minute hang on graceful shutdown of zombie shims.
2. Removes stale `.pid`/`.sock` files so new dockerd can start.
3. Flushes all iptables chains/rules and resets FORWARD to ACCEPT.
4. Starts a fresh `dockerd`.

### Enabling Docker memory accounting (cgroup v2)

By default the Firecracker VM does not delegate the `memory` cgroup v2 controller to child cgroups, so `docker stats` shows `0B / 0B`. The update script fixes this automatically, but if you need to do it manually:

```bash
# 1. Stop dockerd if running.
# 2. Remove Docker's threaded cgroups so root reverts from "domain threaded" to "domain".
sudo rmdir /sys/fs/cgroup/docker/buildkit 2>/dev/null || true
sudo rmdir /sys/fs/cgroup/docker 2>/dev/null || true
# 3. Clear threaded controllers from root subtree, reverting root cgroup to "domain".
sudo sh -c 'echo "-cpuset -cpu -pids" > /sys/fs/cgroup/cgroup.subtree_control' 2>/dev/null || true
# 4. Create init.scope and move all root processes there (cgroup v2 "no internal process" rule).
sudo mkdir -p /sys/fs/cgroup/init.scope
sudo sh -c 'for pid in $(cat /sys/fs/cgroup/cgroup.procs); do echo $pid > /sys/fs/cgroup/init.scope/cgroup.procs 2>/dev/null || true; done'
# 5. Enable memory (and other) controllers.
sudo sh -c 'echo "+cpuset +cpu +pids +memory +io" > /sys/fs/cgroup/cgroup.subtree_control'
# 6. Start dockerd.
```

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

6. **Keep a single service configuration source.**
   - Service enablement and public ports should be configured from one place (`config/services.env`).
   - Compose, scripts, and tests should all use that same config file.

7. **Do not lose roadmap or planning context when refactoring docs.**
   - If content is moved out of `README.md`, preserve it in another markdown file.
   - Add explicit links to moved content.

8. **Language policy (temporary).**
   - All repository Markdown files (`*.md`) must be written in English.
   - When communicating with the user in chat, respond in Russian.
   - For pull request or issue discussions, use the language in which the question/request was asked.
   - If a discussion is mixed-language, default to English.

9. **Services must be operational and log real attack actions.**
   - A service is considered valid only if it supports real interaction flows (for example: authentication attempts, command execution, or SQL statements such as `UPDATE`), not only TCP connection acceptance.
   - Logging must capture explicit attack-related actions, not just connect/disconnect events.

10. **Use fail2ban-provided filters and known log formats whenever available.**
   - Before creating any custom filter or log parser, check the standard fail2ban filter set and service log patterns shipped with fail2ban.
   - If a maintained upstream filter exists for the target service, use it instead of inventing a project-specific equivalent.

11. **Prefer reuse of proven upstream components over custom implementations.**
   - If a production-proven component is already available and suitable, integrate or reference it instead of implementing a new local version from scratch.
   - Prefer integration-based reuse over code copying to reduce maintenance overhead and keep receiving upstream updates.

12. **Disable anonymous access for network services whenever feasible.**
   - For services such as DNS, SMTP, NTP, and similar protocols, disable anonymous or unauthenticated actions when configuration allows it.
   - Prefer configurations that force an attacker to perform explicit credential or access guessing attempts instead of granting default anonymous capabilities.

13. **Do not use project agents for external DDoS or attack traffic generation.**
   - Any built-in service, script, or agent behavior that can be repurposed to generate attack traffic against third-party networks must be disabled or excluded.
   - Testing and simulation traffic must stay scoped to local/lab targets defined for this project only.
