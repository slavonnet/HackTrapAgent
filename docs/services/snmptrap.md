# SNMP trap service implementation details

## Purpose

The SNMP trap service provides an authentication-gated trap receiver endpoint that generates fail2ban events for repeated unauthorized trap submissions.

## Runtime model

- The container runs upstream `snmptrapd` on UDP port `162`.
- Trap ingestion is allowed only for the generated runtime community (v1/v2c) and generated runtime SNMPv3 credentials.
- Unauthorized trap attempts are logged to `/var/log/snmptrap/snmptrapd.log`.
- This log file is mounted through a shared volume and consumed by fail2ban.

## Credentials policy

- No static community or passwords are stored in the repository.
- A random SNMP trap v2c community is generated on every container start.
- A random SNMP trap SNMPv3 auth/priv credential set is generated on every container start.
- Current runtime credentials are written to `/run/hacktrap/snmptrap_credentials.env` inside the container.

## Paths

- Build: `build/snmptrap/`
- Config: `etc/snmptrap/`
- Service defaults: `config/services.env`
- Test: `tests/snmptrap/test_fail2ban_scope.sh`
- fail2ban jail: `fail2ban/snmptrap/jail.local`
- fail2ban filter: `fail2ban/snmptrap/filter.conf`
