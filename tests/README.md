# Testing

Тесты разделены по сервисам.

## Service tests

- `tests/ssh/test_fail2ban_scope.sh` — проверяет SSH + fail2ban:
  - бан IP после серии неуспешных логинов
  - наличие firewall-правила в контейнере
  - отсутствие этого правила на хосте

## Run one service

```bash
./tests/ssh/test_fail2ban_scope.sh
```

## Run selected services

```bash
./tests/run_service_tests.sh ssh
```

`run_service_tests.sh` запускает тесты сервисов параллельно.
