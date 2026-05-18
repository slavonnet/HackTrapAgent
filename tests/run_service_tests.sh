#!/usr/bin/env bash
set -euo pipefail

services=("$@")
config_file="${CONFIG_FILE:-config/services.env}"

if [[ "${#services[@]}" -eq 0 ]]; then
  if [[ ! -f "$config_file" ]]; then
    echo "Missing config file: $config_file"
    exit 1
  fi

  enabled_services="$(awk -F= '/^ENABLED_SERVICES=/{print $2}' "$config_file" | tr -d '[:space:]')"
  IFS=',' read -ra services <<< "$enabled_services"
fi

failed=0
pids=()
services_started=()

for service in "${services[@]}"; do
  [[ -z "$service" ]] && continue
  test_script="tests/${service}/test_fail2ban_scope.sh"
  if [[ ! -x "$test_script" ]]; then
    echo "Missing executable service test: $test_script"
    failed=1
    continue
  fi

  echo "Starting service test: $service"
  "$test_script" &
  pids+=("$!")
  services_started+=("$service")
done

for idx in "${!pids[@]}"; do
  service="${services_started[$idx]}"
  if wait "${pids[$idx]}"; then
    echo "Service test passed: $service"
  else
    echo "Service test failed: $service"
    failed=1
  fi
done

if [[ "$failed" -ne 0 ]]; then
  echo "One or more service tests failed."
  exit 1
fi

echo "All requested service tests passed."
