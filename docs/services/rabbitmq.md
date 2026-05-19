# RabbitMQ service implementation details

## Purpose

The RabbitMQ service provides an AMQP honeypot endpoint that emits fail2ban events for repeated authentication failures.

## Runtime model

- The container runs upstream `rabbitmq:4-management`.
- Runtime credentials are generated at startup and injected through `RABBITMQ_DEFAULT_USER` and `RABBITMQ_DEFAULT_PASS`.
- Failed authentication attempts are logged to `/var/log/rabbitmq/rabbit.log`.
- The log file is mounted via a shared volume and consumed by fail2ban.
- fail2ban monitors AMQP authentication errors from RabbitMQ connection logs.
- By default, management and metrics plugins are disabled at startup (`RABBITMQ_ENABLE_MANAGEMENT=false`) to reduce CPU overhead.
- Low-CPU Erlang scheduler flags are applied by default via `RABBITMQ_LOW_CPU_ERL_ARGS`.
- In low-overhead mode, mnesia state is moved to `/dev/shm/rabbitmq/mnesia` (`RABBITMQ_UNSAFE_RAM_STORAGE=true`) to avoid disk durability costs.
- The container healthcheck uses a lightweight local process probe (`pgrep -x beam.smp`) instead of frequent CLI diagnostics calls to avoid periodic CPU spikes.

## Credentials policy

- No static password is stored in the repository.
- A new random password is generated on every container start for the configured runtime user.
- Current runtime credentials are written to `/run/hacktrap/rabbitmq_credentials.env` inside the container.

## fail2ban filter choice

- Upstream fail2ban does not provide a maintained RabbitMQ filter in the default filter set.
- The project uses a service-local filter at `fail2ban/rabbitmq/filter.conf` that matches RabbitMQ AMQP authentication error records with source IP.

## Paths

- Build: `build/rabbitmq/`
- Config: `etc/rabbitmq/`
- Service defaults: `config/services.env`
- Test: `tests/rabbitmq/test_fail2ban_scope.sh`
- fail2ban jail: `fail2ban/rabbitmq/jail.local`

## Performance-oriented toggles

- `RABBITMQ_ENABLE_MANAGEMENT`: enables/disables the management UI/plugin set.
  - `false` (default): lower CPU footprint.
  - `true`: enables management endpoint (`15672`) for diagnostics.
- `RABBITMQ_UNSAFE_RAM_STORAGE`: when enabled (default), places mnesia state on tmpfs (`/dev/shm`) for faster and less durable operation.
- `RABBITMQ_LOW_CPU_ERL_ARGS`: low-overhead Erlang runtime flags used when `RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS` is not explicitly set.
