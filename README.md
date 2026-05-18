# HackTrapAgent

Легковесный honeypot на Docker Compose для сбора IP-адресов атакующих и их автоматической блокировки в контейнерном контуре.

## Что умеет сейчас

- Поднимает SSH honeypot (`localhost:2222`).
- Сервис `fail2ban` отслеживает неуспешные авторизации и банит IP атакующего.
- Бан применяется только в сетевом namespace контейнера сервиса (не на уровне хоста).

## Быстрый старт

```bash
docker compose up -d --build ssh fail2ban
```

Проверка статуса:

```bash
docker compose ps
docker compose logs -f fail2ban ssh
```

Остановка:

```bash
docker compose down -v
```

## Структура проекта

- `build/<service>/` — Dockerfile и runtime entrypoint сервиса.
- `etc/<service>/` — runtime-конфиги сервиса.
- `fail2ban/<service>/` — fail2ban jail для конкретного сервиса.
- `tests/<service>/` — отдельные интеграционные тесты сервиса.
- `docs/services/<service>.md` — особенности реализации конкретного сервиса.

## Дополнительная документация

- Разработка и локальные тесты: `docs/development/README.md`
- Advanced-конфигурация: `docs/advanced/README.md`
- Реализация SSH-сервиса: `docs/services/ssh.md`

## License

MIT
