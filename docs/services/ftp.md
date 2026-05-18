# FTP service implementation details

## Purpose

The FTP service is used as an additional fail2ban event source for brute-force login attempts.

## Runtime model

- The container runs `vsftpd` in foreground mode.
- `vsftpd` logs are written to `/var/log/ftp/vsftpd.log`.
- This file is mounted via a shared volume and read by fail2ban.
- Local user authentication is enabled to capture realistic failed login traffic.

## Credentials policy

- No static password is stored in the repository.
- New random passwords are generated on every container start for both `root` and the service user.
- Current runtime credentials are written to `/run/hacktrap/ftp_credentials.env` inside the container.

## Paths

- Build: `build/ftp/`
- Config: `etc/ftp/`
- Service defaults: `config/services.env`
- Test: `tests/ftp/test_fail2ban_scope.sh`
- fail2ban jail: `fail2ban/ftp/jail.local`
