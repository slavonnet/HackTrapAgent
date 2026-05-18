# SMB service implementation details

## Purpose

The SMB service provides a file-sharing honeypot endpoint that generates fail2ban events for repeated failed authentications.

## Runtime model

- The container runs upstream `smbd` on TCP port `445`.
- Samba logs are written to `/var/log/smb/log.smbd`.
- This log file is mounted via a shared volume and consumed by fail2ban.
- fail2ban uses the `samba` jail with a local SMB auth-failure filter compatible with this Samba log format.

## Credentials policy

- No static password is stored in the repository.
- New random passwords are generated on every container start for both `root` and the service user.
- Current runtime credentials are written to `/run/hacktrap/smb_credentials.env` inside the container.
- Anonymous SMB access is disabled (`guest ok = no`, `map to guest = never`).

## Paths

- Build: `build/smb/`
- Config: `etc/smb/`
- Service defaults: `config/services.env`
- Test: `tests/smb/test_fail2ban_scope.sh`
- fail2ban jail: `fail2ban/smb/jail.local`
