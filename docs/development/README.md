# Development guide

## Prerequisites

- Docker Engine + Docker Compose plugin
- Linux host with `iptables` access

## Local workflow

1. Build and start services:

   ```bash
   docker compose --profile test up -d --build ssh fail2ban attacker
   ```

2. Run service tests:

   ```bash
   chmod +x tests/run_service_tests.sh tests/ssh/test_fail2ban_scope.sh
   ./tests/run_service_tests.sh ssh
   ```

3. Stop and cleanup:

   ```bash
   docker compose --profile test down -v --remove-orphans
   ```

## Test model

- Каждый сервис имеет собственный тест в `tests/<service>/...`.
- CI запускает тесты по сервисам отдельными job через matrix для параллельности.
