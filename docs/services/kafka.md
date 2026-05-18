# Kafka service implementation details

## Purpose

The Kafka service acts as a TCP honeypot signal source for Kafka-style SASL brute-force attempts.

## Runtime model

- The container runs a lightweight TCP listener on port `9092`.
- Incoming authentication attempts are logged as failed Kafka SASL events to `/var/log/kafka/kafka.log`.
- Non-auth protocol probes are logged separately and do not trigger fail2ban.
- This log file is mounted via a shared volume and read by fail2ban.

## Credentials policy

- No static password is stored in the repository.
- A random runtime credential pair is generated each time the container starts.
- Current runtime credentials are written to `/run/hacktrap/kafka_credentials.env` inside the container.

## Access policy

- Anonymous access is disabled by design: the honeypot only accepts explicit auth-style messages.
- Failed authentication attempts are logged with source IP and selected SASL mechanism.

## Paths

- Build: `build/kafka/`
- Config: `etc/kafka/`
- Service defaults: `config/services.env`
- Test: `tests/kafka/test_fail2ban_scope.sh`
- fail2ban jail: `fail2ban/kafka/jail.local`
- fail2ban filter: `fail2ban/kafka/filter.conf`
