#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
config_file="${CONFIG_FILE:-${project_root}/config/services.env}"
compose_file="${COMPOSE_FILE:-${project_root}/docker-compose.yml}"
runtime_env_file="${RUNTIME_ENV_FILE:-/tmp/hacktrapagent-services.runtime.env}"

if [[ ! -f "$config_file" ]]; then
  echo "Missing config file: $config_file"
  exit 1
fi

docker_cmd="docker"
if ! docker info >/dev/null 2>&1; then
  if command -v sudo >/dev/null 2>&1 && sudo -n docker info >/dev/null 2>&1; then
    docker_cmd="sudo docker"
  else
    if command -v sudo >/dev/null 2>&1 && sudo -n true >/dev/null 2>&1; then
      sudo dockerd &> /tmp/dockerd.log &
      sleep 3
      if sudo -n docker info >/dev/null 2>&1; then
        docker_cmd="sudo docker"
      else
        echo "Cannot access docker daemon after dockerd startup attempt."
        exit 1
      fi
    else
      echo "Cannot access docker daemon."
      exit 1
    fi
  fi
fi

python3 "${project_root}/scripts/prepare_runtime_env.py" \
  --config "$config_file" \
  --output "$runtime_env_file"

enabled_services="$(awk -F= '/^ENABLED_SERVICES=/{print $2}' "$runtime_env_file" | tr -d '[:space:]')"
IFS=',' read -ra service_list <<< "$enabled_services"

startup_services=("fail2ban" "periodic-restart")
for service in "${service_list[@]}"; do
  [[ -z "$service" ]] && continue
  startup_services+=("$service")
done

build_flags=("--build")
if [[ "${SKIP_BUILD:-0}" == "1" ]]; then
  build_flags=()
fi

echo "Using runtime env: $runtime_env_file"
$docker_cmd compose --env-file "$runtime_env_file" -f "$compose_file" up -d "${build_flags[@]}" "${startup_services[@]}"
