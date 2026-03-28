#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
#
# GovClaw LiteLLM proxy — translates OpenAI-format requests from
# OpenShell into Bedrock Converse API calls.
#
# Usage:
#   AWS_BEARER_TOKEN_BEDROCK=... AWS_REGION=... ./scripts/litellm-proxy.sh start
#   ./scripts/litellm-proxy.sh stop
#   ./scripts/litellm-proxy.sh status

set -euo pipefail

LITELLM_PORT="${LITELLM_PORT:-4000}"
LITELLM_DIR="/tmp/govclaw-litellm"
PIDFILE="${LITELLM_DIR}/litellm.pid"
LOGFILE="${LITELLM_DIR}/litellm.log"
CONFIGFILE="${LITELLM_DIR}/config.yaml"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[litellm]${NC} $1"; }
warn()  { echo -e "${YELLOW}[litellm]${NC} $1"; }
fail()  { echo -e "${RED}[litellm]${NC} $1"; exit 1; }

is_running() {
  [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null
}

write_config() {
  local region="${AWS_REGION:-${AWS_DEFAULT_REGION:-us-east-1}}"
  local api_key="${AWS_BEARER_TOKEN_BEDROCK:-}"

  mkdir -p "$LITELLM_DIR"
  chmod 700 "$LITELLM_DIR"

  if [ -n "$api_key" ]; then
    cat > "$CONFIGFILE" <<YAML
model_list:
  - model_name: "*"
    litellm_params:
      model: "bedrock/*"
      api_key: "os.environ/AWS_BEARER_TOKEN_BEDROCK"
      aws_region_name: "${region}"
YAML
  else
    cat > "$CONFIGFILE" <<YAML
model_list:
  - model_name: "*"
    litellm_params:
      model: "bedrock/*"
      aws_access_key_id: "os.environ/AWS_ACCESS_KEY_ID"
      aws_secret_access_key: "os.environ/AWS_SECRET_ACCESS_KEY"
      aws_region_name: "${region}"
YAML
  fi
  chmod 600 "$CONFIGFILE"
}

GOVCLAW_VENV="${HOME}/.govclaw-venv"

ensure_litellm() {
  if [ -x "${GOVCLAW_VENV}/bin/litellm" ]; then
    return 0
  fi
  info "Setting up LiteLLM in ${GOVCLAW_VENV}..."
  python3 -m venv "$GOVCLAW_VENV"
  "${GOVCLAW_VENV}/bin/pip" install -q 'litellm[proxy]'
}

do_start() {
  if is_running; then
    info "Already running (PID $(cat "$PIDFILE"))"
    return 0
  fi

  ensure_litellm

  write_config
  info "Starting LiteLLM proxy on port ${LITELLM_PORT}..."

  nohup "${GOVCLAW_VENV}/bin/litellm" \
    --config "$CONFIGFILE" \
    --port "$LITELLM_PORT" \
    --host 127.0.0.1 \
    --detailed_debug \
    > "$LOGFILE" 2>&1 &
  echo $! > "$PIDFILE"

  local pid
  pid="$(cat "$PIDFILE")"
  info "Started (PID $pid), waiting for health..."

  local attempts=0
  while [ $attempts -lt 30 ]; do
    if curl -sf "http://127.0.0.1:${LITELLM_PORT}/health" >/dev/null 2>&1; then
      info "Healthy — LiteLLM proxy ready on port ${LITELLM_PORT}"
      return 0
    fi
    if ! kill -0 "$pid" 2>/dev/null; then
      fail "LiteLLM exited unexpectedly. Check $LOGFILE"
    fi
    sleep 2
    attempts=$((attempts + 1))
  done

  fail "LiteLLM did not become healthy after 60s. Check $LOGFILE"
}

do_stop() {
  if [ -f "$PIDFILE" ]; then
    local pid
    pid="$(cat "$PIDFILE")"
    if kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null || kill -9 "$pid" 2>/dev/null || true
      info "Stopped (PID $pid)"
    else
      info "Was not running"
    fi
    rm -f "$PIDFILE"
  else
    info "Was not running"
  fi
}

do_status() {
  if is_running; then
    echo -e "  ${GREEN}●${NC} litellm-proxy  (PID $(cat "$PIDFILE"), port ${LITELLM_PORT})"
  else
    echo -e "  ${RED}●${NC} litellm-proxy  (stopped)"
  fi
}

case "${1:-status}" in
  start)  do_start ;;
  stop)   do_stop ;;
  status) do_status ;;
  *)      echo "Usage: $0 {start|stop|status}"; exit 1 ;;
esac
