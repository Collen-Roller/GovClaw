#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
#
# GovClaw installer — gov-ready fork of NemoClaw.
# Sources the upstream install.sh and overrides branding functions.

set -euo pipefail

GOVCLAW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

# Source upstream install.sh (does not run main due to BASH_SOURCE guard)
# shellcheck source=install.sh
. "${GOVCLAW_DIR}/install.sh"

# ---------------------------------------------------------------------------
# Override branding
# ---------------------------------------------------------------------------
print_banner() {
  printf "\n"
  printf "  ${C_GREEN}${C_BOLD}  ██████╗  ██████╗ ██╗   ██╗ ██████╗██╗      █████╗ ██╗    ██╗${C_RESET}\n"
  printf "  ${C_GREEN}${C_BOLD} ██╔════╝ ██╔═══██╗██║   ██║██╔════╝██║     ██╔══██╗██║    ██║${C_RESET}\n"
  printf "  ${C_GREEN}${C_BOLD} ██║  ███╗██║   ██║██║   ██║██║     ██║     ███████║██║ █╗ ██║${C_RESET}\n"
  printf "  ${C_GREEN}${C_BOLD} ██║   ██║██║   ██║╚██╗ ██╔╝██║     ██║     ██╔══██║██║███╗██║${C_RESET}\n"
  printf "  ${C_GREEN}${C_BOLD} ╚██████╔╝╚██████╔╝ ╚████╔╝ ╚██████╗███████╗██║  ██║╚███╔███╔╝${C_RESET}\n"
  printf "  ${C_GREEN}${C_BOLD}  ╚═════╝  ╚═════╝   ╚═══╝   ╚═════╝╚══════╝╚═╝  ╚═╝ ╚══╝╚══╝${C_RESET}\n"
  printf "\n"
  printf "  ${C_DIM}Gov-ready OpenClaw sandbox.  v%s  (fork of NemoClaw)${C_RESET}\n" "$NEMOCLAW_VERSION"
  printf "\n"
}

print_done() {
  local elapsed=$((SECONDS - _INSTALL_START))
  local sandbox_name
  sandbox_name="$(resolve_default_sandbox_name)"
  info "=== Installation complete ==="
  printf "\n"
  printf "  ${C_GREEN}${C_BOLD}GovClaw${C_RESET}  ${C_DIM}(%ss)${C_RESET}\n" "$elapsed"
  printf "\n"
  printf "  ${C_GREEN}Your OpenClaw Sandbox is live.${C_RESET}\n"
  printf "  ${C_DIM}Sandbox in, break things, and tell us what you find.${C_RESET}\n"
  printf "\n"
  printf "  ${C_GREEN}Next:${C_RESET}\n"
  printf "  %s$%s govclaw %s connect\n" "$C_GREEN" "$C_RESET" "$sandbox_name"
  printf "  %ssandbox@%s$%s openclaw tui\n" "$C_GREEN" "$sandbox_name" "$C_RESET"
  printf "\n"
  printf "  ${C_BOLD}GitHub${C_RESET}  ${C_DIM}https://github.com/Collen-Roller/GovClaw${C_RESET}\n"
  printf "\n"
}

usage() {
  printf "\n"
  printf "  ${C_BOLD}GovClaw Installer${C_RESET}  ${C_DIM}v%s${C_RESET}\n\n" "$NEMOCLAW_VERSION"
  printf "  ${C_DIM}Usage:${C_RESET}\n"
  printf "    bash govclaw-install.sh\n"
  printf "    bash govclaw-install.sh [options]\n\n"
  printf "  ${C_DIM}Options:${C_RESET}\n"
  printf "    --non-interactive    Skip prompts (uses env vars / defaults)\n"
  printf "    --version, -v        Print installer version and exit\n"
  printf "    --help, -h           Show this help message and exit\n\n"
  printf "  ${C_DIM}Environment:${C_RESET}\n"
  printf "    NVIDIA_API_KEY                API key (skips credential prompt)\n"
  printf "    NEMOCLAW_NON_INTERACTIVE=1    Same as --non-interactive\n"
  printf "    NEMOCLAW_SANDBOX_NAME         Sandbox name to create/use\n"
  printf "    NEMOCLAW_RECREATE_SANDBOX=1   Recreate an existing sandbox\n"
  printf "    NEMOCLAW_PROVIDER             cloud | ollama | nim | vllm | bedrock\n"
  printf "    NEMOCLAW_MODEL                Inference model to configure\n"
  printf "    NEMOCLAW_POLICY_MODE          suggested | custom | skip\n"
  printf "    NEMOCLAW_POLICY_PRESETS       Comma-separated policy presets\n"
  printf "    AWS_BEARER_TOKEN_BEDROCK      Bedrock API key (simplest auth)\n"
  printf "    AWS_ACCESS_KEY_ID             IAM access key (alternative)\n"
  printf "    AWS_SECRET_ACCESS_KEY         IAM secret key\n"
  printf "\n"
}

# Intercept --version to show GovClaw branding
for _arg in "$@"; do
  case "$_arg" in
    --version | -v)
      printf "govclaw-installer v%s\n" "$NEMOCLAW_VERSION"
      exit 0
      ;;
  esac
done

# Run with GovClaw branding
main "$@"
