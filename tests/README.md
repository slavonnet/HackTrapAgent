# Testing

Tests are split by service.

## Service tests

- `tests/ssh/test_fail2ban_scope.sh` — validates SSH + fail2ban:
  - IP ban after repeated failed logins
  - firewall rule exists inside the container scope
  - matching rule is absent on the host

## Run one service

```bash
./tests/ssh/test_fail2ban_scope.sh
```

## Run selected services

```bash
./tests/run_service_tests.sh ssh
```

`run_service_tests.sh` runs service tests in parallel.
