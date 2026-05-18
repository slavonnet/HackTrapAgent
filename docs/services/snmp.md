# SNMP service implementation details

## Purpose

The SNMP service provides an authentication-focused honeypot endpoint for SNMP v1/v2c/v3 and produces fail2ban events for repeated failed access attempts.

## Runtime model

- The container runs upstream `snmpd` on UDP port `161`.
- SNMP v1/v2c requests are accepted only for the generated runtime community.
- SNMPv3 requests are accepted only for the generated runtime user and auth/priv credentials.
- Authentication failures are logged to `/var/log/snmp/snmpd.log`.
- This log file is mounted through a shared volume and consumed by fail2ban.

## Credentials policy

- No static community or passwords are stored in the repository.
- A random SNMP v2c community is generated on every container start.
- A random SNMPv3 auth/priv credential set is generated on every container start.
- Current runtime credentials are written to `/run/hacktrap/snmp_credentials.env` inside the container.

## Paths

- Build: `build/snmp/`
- Config: `etc/snmp/`
- Service defaults: `config/services.env`
- Test: `tests/snmp/test_fail2ban_scope.sh`
- fail2ban jail: `fail2ban/snmp/jail.local`
- fail2ban filter: `fail2ban/snmp/filter.conf`
