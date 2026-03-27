#!/usr/bin/env node
// SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
// SPDX-License-Identifier: Apache-2.0
//
// GovClaw CLI — gov-ready fork of NemoClaw.
// Thin wrapper that patches branding then delegates to nemoclaw.js dispatch.

const path = require("path");

const B = "\x1b[1m";
const D = "\x1b[2m";
const G = "\x1b[32m";
const R = "\x1b[0m";

function govclawHelp() {
  const pkg = require(path.join(__dirname, "..", "package.json"));
  console.log(`
  ${B}${G}GovClaw${R}  ${D}v${pkg.version}${R}  ${D}(fork of NemoClaw)${R}
  ${D}Gov-ready, secure AI agent sandboxing with a single command.${R}

  ${G}Getting Started:${R}
    ${B}govclaw onboard${R}                  Configure inference endpoint and credentials
    govclaw setup-spark              Set up on DGX Spark ${D}(fixes cgroup v2 + Docker)${R}

  ${G}Sandbox Management:${R}
    ${B}govclaw list${R}                     List all sandboxes
    govclaw <name> connect           Shell into a running sandbox
    govclaw <name> status            Sandbox health + NIM status
    govclaw <name> logs ${D}[--follow]${R}   Stream sandbox logs
    govclaw <name> destroy           Stop NIM + delete sandbox ${D}(--yes to skip prompt)${R}

  ${G}Policy Presets:${R}
    govclaw <name> policy-add        Add a network or filesystem policy preset
    govclaw <name> policy-list       List presets ${D}(● = applied)${R}

  ${G}Deploy:${R}
    govclaw deploy <instance>        Deploy to a Brev VM and start services

  ${G}Services:${R}
    govclaw start                    Start auxiliary services ${D}(Telegram, tunnel)${R}
    govclaw stop                     Stop all services
    govclaw status                   Show sandbox list and service status

  Troubleshooting:
    govclaw debug [--quick]          Collect diagnostics for bug reports
    govclaw debug --output FILE      Save diagnostics tarball for GitHub issues

  Cleanup:
    govclaw uninstall [flags]        Run uninstall.sh (local first, curl fallback)

  ${G}Uninstall flags:${R}
    --yes                            Skip the confirmation prompt
    --keep-openshell                 Leave the openshell binary installed
    --delete-models                  Remove GovClaw-pulled Ollama models

  ${D}Powered by NVIDIA OpenShell · Nemotron · Agent Toolkit
  Credentials saved in ~/.nemoclaw/credentials.json (mode 600)${R}
  ${D}https://github.com/Collen-Roller/GovClaw${R}
`);
}

// Patch process.argv[1] so nemoclaw.js prints "govclaw" in error messages
const originalArgv1 = process.argv[1];
process.argv[1] = __filename;

// Intercept: if no command or help requested, show GovClaw help and exit
const cmd = process.argv[2];
if (!cmd || cmd === "help" || cmd === "--help" || cmd === "-h") {
  govclawHelp();
  process.exit(0);
}

if (cmd === "--version" || cmd === "-v") {
  const pkg = require(path.join(__dirname, "..", "package.json"));
  console.log(`govclaw v${pkg.version}`);
  process.exit(0);
}

// For all other commands, delegate to nemoclaw.js which handles dispatch
require("./nemoclaw.js");
