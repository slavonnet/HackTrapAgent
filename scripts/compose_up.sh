#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
config_file="${CONFIG_FILE:-${project_root}/config/services.env}"
compose_file="${COMPOSE_FILE:-${project_root}/docker-compose.yml}"

if [[ ! -f "$config_file" ]]; then
  echo "Missing config file: $config_file"
  exit 1
fi

docker_cmd="docker"
if ! docker info >/dev/null 2>&1; then
  if command -v sudo >/dev/null 2>&1 && sudo -n docker info >/dev/null 2>&1; then
    docker_cmd="sudo docker"
  else
    echo "Cannot access docker daemon."
    exit 1
  fi
fi

enabled_services="$(awk -F= '/^ENABLED_SERVICES=/{print $2}' "$config_file" | tr -d '[:space:]')"
IFS=',' read -ra service_list <<< "$enabled_services"

startup_services=("fail2ban")
for service in "${service_list[@]}"; do
  [[ -z "$service" ]] && continue
  startup_services+=("$service")
done

$docker_cmd compose --env-file "$config_file" -f "$compose_file" up -d --build "${startup_services[@]}"
