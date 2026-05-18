# NFS service implementation details

## Purpose

The NFS service provides a real NFSv4 endpoint that generates fail2ban signals from repeated remote RPC client registration probes.

## Runtime model

- The container runs `nfs-ganesha` in foreground mode on TCP port `2049`.
- `nfs-ganesha` logs are written to `/var/log/nfs/ganesha.log`.
- This log file is mounted via a shared volume and read by fail2ban.
- NFSv4 `SETCLIENTID` request attempts are logged with source IPs and used as ban triggers.

## Anonymous access policy

- Export defaults are set to `Access_Type = NONE`.
- A dedicated export is restricted to explicit clients from `NFS_ALLOWED_CLIENTS`.
- The default runtime value is `127.0.0.1/32`, which forces remote clients to perform denied probe attempts.

## Filter strategy

- Debian fail2ban package does not provide a maintained upstream filter for nfs-ganesha request logs.
- The jail uses a service-scoped `nfs-ganesha-rpc` filter matching native `nfs_rpc_process_request` debug traces with source IP (`Program 100003`, `Version 4`, function `0` or `1`).
- Filter file: `fail2ban/nfs/filter.d/nfs-ganesha-rpc.conf`.

## Credentials policy

- NFS service does not use passwords in this implementation.
- No static credentials are stored in the repository for this service.

## Traffic safety scope

- Test traffic for this service is restricted to local Docker Compose lab targets only.
- The service and tests are not intended for generating external attack or stress traffic.

## Paths

- Build: `build/nfs/`
- Config: `etc/nfs/`
- Service defaults: `config/services.env`
- Test: `tests/nfs/test_fail2ban_scope.sh`
- fail2ban jail: `fail2ban/nfs/jail.local`
- fail2ban filter: `fail2ban/nfs/filter.d/nfs-ganesha-rpc.conf`
