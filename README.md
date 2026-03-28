# GovClaw: Gov-Ready AI Agent Sandboxing

<!-- start-badges -->
[![License](https://img.shields.io/badge/License-Apache_2.0-blue)](https://github.com/Collen-Roller/GovClaw/blob/main/LICENSE)
[![Security Policy](https://img.shields.io/badge/Security-Report%20a%20Vulnerability-red)](https://github.com/Collen-Roller/GovClaw/blob/main/SECURITY.md)
[![Project Status](https://img.shields.io/badge/status-alpha-orange)](https://github.com/Collen-Roller/GovClaw/blob/main/CHANGES.md)
[![Fork](https://img.shields.io/badge/fork%20of-NemoClaw-76B900)](https://github.com/NVIDIA/NemoClaw)
<!-- end-badges -->

GovClaw is a government-focused fork of [NVIDIA NemoClaw](https://github.com/NVIDIA/NemoClaw) that adds **AWS Bedrock** support, **Mattermost** integration, and other features for defense and government environments.

It runs [OpenClaw](https://openclaw.ai) agents inside [NVIDIA OpenShell](https://github.com/NVIDIA/OpenShell) sandboxes with policy-enforced network egress, filesystem isolation, and managed inference routing.

> **Alpha software** — GovClaw inherits NemoClaw's alpha status. Interfaces, APIs, and behavior may change without notice.

---

## What GovClaw Adds

| Feature | Description |
|---------|-------------|
| **AWS Bedrock** | First-class inference provider with API key auth, dynamic model discovery, and native `bedrock-converse-stream` support. |
| **Mattermost** | Policy preset for DoD/gov messaging (`*.cloud.mattermost.com`). |
| **Dynamic model list** | Fetches available models from Bedrock's `ListFoundationModels` API based on your region and access. |
| **Policy fix** | Typing preset names directly at the policy prompt now works (e.g. "discord" applies discord, not the defaults). |

All upstream NemoClaw providers remain available: NVIDIA Endpoints, OpenAI, Anthropic, Google Gemini, and Local Ollama.

---

## Quick Start

### Prerequisites

- **Linux** (Ubuntu 22.04+) or macOS with Docker
- **Node.js** 20+ and **npm** 10+
- **Python 3** (for LiteLLM proxy, optional)
- **Docker** running
- **[OpenShell](https://github.com/NVIDIA/OpenShell)** installed

For AWS Bedrock: a [Bedrock API key](https://console.aws.amazon.com/bedrock/home#/api-keys) (long-term recommended) and [model access](https://console.aws.amazon.com/bedrock/home#/modelaccess) enabled for the models you want to use.

### Install

```bash
# Install OpenShell
curl -LsSf https://raw.githubusercontent.com/NVIDIA/OpenShell/main/install.sh | sh

# Clone GovClaw
git clone https://github.com/Collen-Roller/GovClaw.git
cd GovClaw

# Run the GovClaw installer
./govclaw-install.sh
```

The installer guides you through:

1. **Node.js** — installs via nvm if missing
2. **GovClaw CLI** — links the `govclaw` command
3. **LiteLLM Proxy** — installs in a Python venv (for Bedrock)
4. **Onboarding** — configure inference, create sandbox, apply policies

### Using Bedrock

When the onboarding wizard shows inference options, select **AWS Bedrock**:

```text
Inference options:
  1) NVIDIA Endpoints (recommended)
  2) OpenAI
  3) Other OpenAI-compatible endpoint
  4) Anthropic
  5) Other Anthropic-compatible endpoint
  6) Google Gemini
  7) AWS Bedrock (Amazon Web Services)
  8) Local Ollama (localhost:11434)

Choose [1]: 7
```

You'll be prompted for:
- **AWS region** (auto-detected from `~/.aws/config` or defaults to `us-east-1`)
- **Bedrock API key** (saved to `~/.nemoclaw/credentials.json`)

The setup then fetches your available models dynamically and lets you pick one.

### Non-Interactive Install (CI/CD)

```bash
export AWS_BEARER_TOKEN_BEDROCK="ABSK..."
export AWS_REGION=us-east-2
export NEMOCLAW_PROVIDER=bedrock
export NEMOCLAW_MODEL=us.anthropic.claude-3-5-sonnet-20241022-v2:0
./govclaw-install.sh --non-interactive
```

### Connect and Chat

```bash
# Connect to the sandbox
govclaw my-sandbox connect

# Inside the sandbox, open the TUI
openclaw tui

# Or send a single message via CLI
openclaw agent --agent main --local -m "hello" --session-id test
```

---

## Inference Providers

| Provider | Auth | Notes |
|----------|------|-------|
| **AWS Bedrock** | Bedrock API key (`AWS_BEARER_TOKEN_BEDROCK`) | Native `bedrock-converse-stream`. Dynamic model discovery. |
| NVIDIA Endpoints | `NVIDIA_API_KEY` | Curated models on `integrate.api.nvidia.com`. |
| OpenAI | `OPENAI_API_KEY` | GPT models. |
| Anthropic | `ANTHROPIC_API_KEY` | Claude models. |
| Google Gemini | `GEMINI_API_KEY` | Gemini models via OpenAI-compatible endpoint. |
| Local Ollama | None | Local models on `localhost:11434`. |

### Bedrock Model Access

Bedrock only shows models you have access to. To enable more models:

1. Go to [Bedrock Model Access](https://console.aws.amazon.com/bedrock/home#/modelaccess) in your region
2. Click **Manage model access**
3. Enable the models you want (Claude, Llama, Nova, etc.)

---

## Policy Presets

GovClaw includes policy presets for common integrations. Apply during setup or later with `govclaw <name> policy-add`.

| Preset | Description |
|--------|-------------|
| `pypi` | Python Package Index access (suggested) |
| `npm` | npm and Yarn registry access (suggested) |
| `mattermost` | Mattermost API and webhook access |
| `discord` | Discord API, gateway, and CDN |
| `slack` | Slack API and webhooks |
| `telegram` | Telegram Bot API |
| `docker` | Docker Hub and NVIDIA container registry |
| `huggingface` | Hugging Face Hub, LFS, and Inference API |
| `jira` | Jira and Atlassian Cloud |
| `outlook` | Microsoft Outlook and Graph API |

---

## Key Commands

| Command | Description |
|---------|-------------|
| `govclaw onboard` | Interactive setup wizard |
| `govclaw list` | List all sandboxes |
| `govclaw <name> connect` | Shell into a running sandbox |
| `govclaw <name> status` | Sandbox health and inference status |
| `govclaw <name> logs --follow` | Stream sandbox logs |
| `govclaw <name> destroy` | Delete sandbox |
| `govclaw <name> policy-add` | Add a policy preset |
| `govclaw <name> policy-list` | List presets (applied/available) |

The `nemoclaw` command also works as an alias.

---

## Architecture

```text
Host
  └── Docker
       └── OpenShell Gateway
            └── k3s
                 └── GovClaw Sandbox Pod
                      └── OpenClaw Agent + GovClaw Plugin
                           └── bedrock-converse-stream → Bedrock Runtime
```

For Bedrock, OpenClaw uses its native `bedrock-converse-stream` API to talk directly to AWS Bedrock from inside the sandbox. The network policy allows `*.amazonaws.com` with TLS passthrough.

---

## Upstream Compatibility

GovClaw is designed to stay mergeable with upstream NemoClaw:

- **Bedrock** is integrated as a `REMOTE_PROVIDER_CONFIG` entry, following the same pattern as OpenAI, Anthropic, and Gemini
- **GovClaw-specific files** (`govclaw-install.sh`, `bin/govclaw.js`) don't modify upstream files
- **Feature additions** (Mattermost preset, policy fix) are additive and contribution-ready

See [CHANGES.md](CHANGES.md) for a full changelog.

---

## Learn More

- [NemoClaw Documentation](https://docs.nvidia.com/nemoclaw/latest/)
- [DGX Spark Setup](spark-install.md)
- [OpenShell](https://github.com/NVIDIA/OpenShell)
- [OpenClaw](https://openclaw.ai)

## License

This project is licensed under the [Apache License 2.0](LICENSE).
