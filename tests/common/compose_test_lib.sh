#!/usr/bin/env bash

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
compose_file="${COMPOSE_FILE:-${project_root}/docker-compose.yml}"
config_file="${CONFIG_FILE:-${project_root}/config/services.env}"
runtime_config_generated=0
runtime_config_cleanup=0

load_service_config() {
  if [[ ! -f "$config_file" ]]; then
    echo "Missing config file: $config_file"
    exit 1
  fi

  local runtime_config_file="${RUNTIME_CONFIG_FILE:-/tmp/hacktrapagent-tests-$$.env}"
  if ! python3 "${project_root}/scripts/prepare_runtime_env.py" \
    --config "$config_file" \
    --output "$runtime_config_file" \
    --quiet; then
    echo "Failed to prepare runtime services config for tests."
    exit 1
  fi

  config_file="$runtime_config_file"
  runtime_config_generated=1
  if [[ -z "${RUNTIME_CONFIG_FILE:-}" ]]; then
    runtime_config_cleanup=1
  fi

  set -a
  # shellcheck source=/dev/null
  source "$config_file"
  set +a
}

set_compose_project_name() {
  local service_name="$1"
  export COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-hacktrap-${service_name}-$$}"
}

init_docker_cmd() {
  if ! command -v docker >/dev/null 2>&1; then
    echo "docker is required"
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
}

init_host_iptables_bins() {
  host_prefix=""
  if command -v sudo >/dev/null 2>&1 && sudo -n true >/dev/null 2>&1; then
    host_prefix="sudo "
  fi

  host_iptables_bins=()
  for bin in iptables iptables-legacy; do
    if command -v "$bin" >/dev/null 2>&1; then
      if ${host_prefix}${bin} -S >/dev/null 2>&1; then
        host_iptables_bins+=("$bin")
      fi
    fi
  done

  if [[ "${#host_iptables_bins[@]}" -eq 0 ]]; then
    echo "Cannot inspect host iptables; test cannot verify container-only scope."
    exit 1
  fi
}

compose() {
  local project_name="${COMPOSE_PROJECT_NAME:-hacktrap-test}"
  $docker_cmd compose --project-name "$project_name" --env-file "$config_file" -f "$compose_file" "$@"
}

get_compose_profile_args() {
  local profiles=("test")
  local enabled_services_raw="${ENABLED_SERVICES:-}"
  IFS=',' read -ra enabled_services <<< "$enabled_services_raw"
  for service in "${enabled_services[@]}"; do
    service="$(echo "$service" | xargs)"
    [[ -z "$service" ]] && continue
    profiles+=("$service")
  done

  local args=()
  for profile in "${profiles[@]}"; do
    args+=(--profile "$profile")
  done

  printf '%s\n' "${args[@]}"
}

cleanup_compose() {
  mapfile -t profile_args < <(get_compose_profile_args)
  compose "${profile_args[@]}" down -v --remove-orphans >/dev/null 2>&1 || true

  if [[ "$runtime_config_generated" -eq 1 && "$runtime_config_cleanup" -eq 1 && -f "$config_file" ]]; then
    rm -f "$config_file"
  fi
}

wait_for_exec_success() {
  local service="$1"
  local command="$2"
  local retries="${3:-40}"
  for _ in $(seq 1 "$retries"); do
    if compose exec -T "$service" sh -lc "$command" >/dev/null 2>&1; then
      return 0
    fi
    sleep 2
  done

  echo "Service did not become ready: ${service}, command: ${command}"
  return 1
}

get_attacker_ip() {
  compose exec -T attacker sh -lc "ip -4 -o addr show eth0 | awk '{print \$4}' | cut -d/ -f1" | tr -d '\r'
}

assert_ip_not_banned_on_host() {
  local ip="$1"
  for bin in "${host_iptables_bins[@]}"; do
    if ${host_prefix}${bin} -S | grep -F "$ip" >/dev/null; then
      echo "Host ${bin} unexpectedly contains banned IP: $ip"
      return 1
    fi
  done
}
