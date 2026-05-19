#!/bin/sh
set -eu

project_name="${COMPOSE_PROJECT_NAME:-hacktrapagent}"
interval="${RESTART_INTERVAL_SECONDS:-1800}"
enabled_services="${ENABLED_SERVICES:-}"

case "$interval" in
  ''|*[!0-9]*)
    interval=1800
    ;;
esac

if [ "$interval" -lt 1 ]; then
  interval=1800
fi

while true; do
  sleep "$interval"

  for service in $(printf '%s' "$enabled_services" | tr ',' ' '); do
    case "$service" in
      ''|fail2ban|periodic-restart|attacker)
        continue
        ;;
    esac

    targets="$(
      docker ps -q \
        --filter "label=com.docker.compose.project=${project_name}" \
        --filter "label=com.docker.compose.service=${service}"
    )"

    if [ -n "$targets" ]; then
      docker stop $targets >/dev/null || true
      docker start $targets >/dev/null || true
    fi
  done
done
