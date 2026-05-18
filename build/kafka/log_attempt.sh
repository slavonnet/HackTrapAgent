#!/usr/bin/env bash
set -euo pipefail

payload=""
if IFS= read -r payload; then
  payload="$(printf "%s" "$payload" | tr -d '\r')"
fi

peer_addr="${SOCAT_PEERADDR:-0.0.0.0}"
peer_port="${SOCAT_PEERPORT:-0}"
expected_user="${KAFKA_HONEYPOT_USER:-trap}"
timestamp="$(date "+%Y-%m-%d %H:%M:%S")"

if [[ "$payload" == AUTH* ]]; then
  mechanism="PLAIN"
  user_name="unknown"

  if [[ "$payload" =~ mechanism=([^[:space:]]+) ]]; then
    mechanism="${BASH_REMATCH[1]}"
  fi

  if [[ "$payload" =~ user=([^[:space:]]+) ]]; then
    user_name="${BASH_REMATCH[1]}"
  fi

  printf "%s kafka[%s]: SASL_AUTH_FAILED [AF_INET]%s:%s user=%s expected_user=%s mechanism=%s\n" \
    "$timestamp" "$$" "$peer_addr" "$peer_port" "$user_name" "$expected_user" "$mechanism" >> /var/log/kafka/kafka.log
else
  printf "%s kafka[%s]: PROTOCOL_PROBE [AF_INET]%s:%s payload=%q\n" \
    "$timestamp" "$$" "$peer_addr" "$peer_port" "$payload" >> /var/log/kafka/kafka.log
fi
