# MongoDB service implementation details

## Purpose

The MongoDB service is used as an additional fail2ban event source for brute-force authentication attempts.

## Runtime model

- The container runs upstream `mongod` and exposes TCP `27017`.
- Authentication failures are logged to `/var/log/mongodb/mongodb.log`.
- This log file is mounted via a shared volume and consumed by fail2ban.
- Startup logic resets local data and rotates runtime credentials on each container start.

## Credentials policy

- No static password is stored in the repository.
- New random passwords are generated on every container start for:
  - `root` in the `admin` database
  - optional runtime service user from `etc/mongodb/users.conf`
- Current runtime credentials are written to `/run/hacktrap/mongodb_credentials.env` inside the container.

## Paths

- Build: `build/mongodb/`
- Config: `etc/mongodb/`
- Service defaults: `config/services.env`
- Test: `tests/mongodb/test_fail2ban_scope.sh`
- fail2ban jail: `fail2ban/mongodb/jail.local`
- fail2ban filter: `fail2ban/mongodb/filter.conf`

## fail2ban filter choice

- The Debian `fail2ban` package ships an upstream `mongodb-auth` filter.
- MongoDB 8 writes JSON-formatted auth failure logs (`"msg":"Failed to authenticate"`), which are not parsed by that upstream filter.
- For this reason, the service uses a local JSON-aware filter in `fail2ban/mongodb/filter.conf`.
