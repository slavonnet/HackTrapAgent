# Elasticsearch service implementation details

## Purpose

The Elasticsearch service acts as an HTTP-based honeypot endpoint for authentication brute-force attempts.

## Runtime model

- The container runs an Elasticsearch-like API listener on TCP `9200`.
- Requests require HTTP Basic authentication.
- Failed authentication attempts are logged to `/var/log/elasticsearch/elasticsearch.log`.
- Authenticated API actions (for example `/_search`) are also logged to capture explicit attack behavior.
- This log file is mounted via shared volume and read by fail2ban.

## Credentials policy

- No static password is stored in the repository.
- A random password is generated on each container start for the configured service user.
- Current runtime credentials are written to `/run/hacktrap/elasticsearch_credentials.env` inside the container.

## Paths

- Build: `build/elasticsearch/`
- Config: `etc/elasticsearch/`
- Service defaults: `config/services.env`
- Test: `tests/elasticsearch/test_fail2ban_scope.sh`
- fail2ban jail: `fail2ban/elasticsearch/jail.local`
- fail2ban filter: `fail2ban/elasticsearch/filter.conf`

## fail2ban filter choice

- The Debian `fail2ban` package used in this project does not ship a maintained `filter.d/elasticsearch.conf`.
- For this reason, the project keeps a dedicated service-local Elasticsearch filter under `fail2ban/elasticsearch/filter.conf`.
