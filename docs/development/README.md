# Development guide

## Prerequisites

- Docker Engine + Docker Compose plugin
- Linux host with `iptables` access

## Local workflow

1. Build and start services:

   ```bash
   ./scripts/compose_up.sh
   ```

2. Run service tests:

   ```bash
   chmod +x tests/run_service_tests.sh tests/common/compose_test_lib.sh tests/ssh/test_fail2ban_scope.sh tests/ftp/test_fail2ban_scope.sh tests/ntp/test_fail2ban_scope.sh tests/postgresql/test_fail2ban_scope.sh tests/mysql/test_fail2ban_scope.sh tests/bgp/test_fail2ban_scope.sh tests/openvpn/test_fail2ban_scope.sh
   ./tests/run_service_tests.sh
   ```

3. Stop and cleanup:

   ```bash
   ./scripts/compose_down.sh
   ```

## Test model

- Each service must have its own test under `tests/<service>/...`.
- CI runs service tests as separate matrix jobs for parallel execution.
- Shared logic belongs in `tests/common/`.
- Service/port enablement is controlled from `config/services.env`.
