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
  # Use the most recently created sandbox, not the stored default
  sandbox_name="$(
    node -e '
      const fs = require("fs");
      try {
        const data = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
        const entries = Object.values(data.sandboxes || {});
        entries.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
        process.stdout.write(entries[0]?.name || "");
      } catch {}
    ' "$HOME/.nemoclaw/sandboxes.json" 2>/dev/null || true
  )"
  sandbox_name="${sandbox_name:-$(resolve_default_sandbox_name)}"
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

# Override install to use --force on npm link and clone from GovClaw repo
install_nemoclaw() {
  if [[ -f "./package.json" ]] && grep -q '"name":' ./package.json 2>/dev/null; then
    info "GovClaw package.json found in current directory — installing from source…"
    spin "Preparing OpenClaw package" bash -c "$(declare -f info warn pre_extract_openclaw); pre_extract_openclaw \"\$1\"" _ "$(pwd)" \
      || warn "Pre-extraction failed — npm install may fail if openclaw tarball is broken"
    spin "Installing GovClaw dependencies" npm install --ignore-scripts
    spin "Building GovClaw plugin" bash -c 'cd nemoclaw && npm install --ignore-scripts && npm run build'
    spin "Linking GovClaw CLI" npm link --force
  else
    info "Installing GovClaw from GitHub…"
    local govclaw_src="${HOME}/.nemoclaw/source"
    rm -rf "$govclaw_src"
    mkdir -p "$(dirname "$govclaw_src")"
    spin "Cloning GovClaw source" git clone --depth 1 https://github.com/Collen-Roller/GovClaw.git "$govclaw_src"
    spin "Preparing OpenClaw package" bash -c "$(declare -f info warn pre_extract_openclaw); pre_extract_openclaw \"\$1\"" _ "$govclaw_src" \
      || warn "Pre-extraction failed — npm install may fail if openclaw tarball is broken"
    spin "Installing GovClaw dependencies" bash -c "cd \"$govclaw_src\" && npm install --ignore-scripts"
    spin "Building GovClaw plugin" bash -c "cd \"$govclaw_src\"/nemoclaw && npm install --ignore-scripts && npm run build"
    spin "Linking GovClaw CLI" bash -c "cd \"$govclaw_src\" && npm link --force"
  fi

  refresh_path
  ensure_nemoclaw_shim || true
}

# Install LiteLLM proxy (needed for Bedrock inference translation)
install_litellm_proxy() {
  local venv="${HOME}/.govclaw-venv"
  if command_exists python3; then
    if [ -x "${venv}/bin/litellm" ]; then
      ok "LiteLLM already installed (${venv})"
    else
      spin "Creating GovClaw Python venv" python3 -m venv "$venv"
      spin "Installing LiteLLM proxy" "${venv}/bin/pip" install -q 'litellm[proxy]'
    fi
  else
    warn "Python 3 not found — LiteLLM proxy (needed for Bedrock) will not be available."
  fi
}

# Override main to add LiteLLM install step
main() {
  NON_INTERACTIVE=""
  for arg in "$@"; do
    case "$arg" in
      --non-interactive) NON_INTERACTIVE=1 ;;
      --version | -v)
        printf "govclaw-installer v%s\n" "$NEMOCLAW_VERSION"
        exit 0
        ;;
      --help | -h)
        usage
        exit 0
        ;;
      *)
        usage
        error "Unknown option: $arg"
        ;;
    esac
  done
  NON_INTERACTIVE="${NON_INTERACTIVE:-${NEMOCLAW_NON_INTERACTIVE:-}}"
  export NEMOCLAW_NON_INTERACTIVE="${NON_INTERACTIVE}"

  TOTAL_STEPS=4
  _INSTALL_START=$SECONDS
  print_banner

  step 1 "Node.js"
  install_nodejs
  ensure_supported_runtime

  step 2 "GovClaw CLI"
  install_nemoclaw
  verify_nemoclaw

  step 3 "LiteLLM Proxy"
  install_litellm_proxy

  step 4 "Onboarding"
  if command_exists nemoclaw; then
    run_onboard
  else
    warn "Skipping onboarding — nemoclaw is not on PATH. Run 'govclaw onboard' after updating your PATH."
  fi

  print_done
  post_install_message
}

# Run with GovClaw branding (main is overridden above)
main "$@"
