#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
config_file="${CONFIG_FILE:-${project_root}/config/services.env}"
compose_file="${COMPOSE_FILE:-${project_root}/docker-compose.yml}"

docker_cmd="docker"
if ! docker info >/dev/null 2>&1; then
  if command -v sudo >/dev/null 2>&1 && sudo -n docker info >/dev/null 2>&1; then
    docker_cmd="sudo docker"
  else
    echo "Cannot access docker daemon."
    exit 1
  fi
fi

$docker_cmd compose --env-file "$config_file" -f "$compose_file" --profile test down -v --remove-orphans
