# GovClaw Changes

GovClaw is a government-focused fork of [NemoClaw](https://github.com/NVIDIA/NemoClaw),
adding features for secure AI agent sandboxing in government and defense environments.

---

## Unreleased — 2026-03-27

### Added

- **AWS Bedrock inference provider** — New option in the setup script.
  Supports three auth methods:
  - Bedrock API key (`AWS_BEARER_TOKEN_BEDROCK`) — simplest, single token from AWS console
  - AWS profile (`~/.aws/credentials`) — auto-detected, profile picker in setup
  - IAM access key + secret key — manual entry fallback
  - Region auto-detected from `~/.aws/config`, defaults to `us-east-1`
  - Files: `bin/lib/onboard.js`, `bin/lib/inference-config.js`

- **Bedrock model picker** — Five curated models available during setup:
  - Claude Sonnet 4 (Anthropic)
  - Claude 3.5 Sonnet v2 (Anthropic)
  - Llama 3.3 70B (Meta)
  - Nova Pro (Amazon)
  - Mistral Large (Mistral)
  - File: `bin/lib/inference-config.js`

- **Bedrock inference profile** in blueprint (`nemoclaw-blueprint/blueprint.yaml`)
  - Registered as OpenAI-compatible provider pointing at `bedrock-runtime.{region}.amazonaws.com`

- **Bedrock network policy** (`nemoclaw-blueprint/policies/openclaw-sandbox.yaml`)
  - Allows outbound to `*.amazonaws.com:443` for Bedrock runtime + STS auth

- **Mattermost policy preset** (`nemoclaw-blueprint/policies/presets/mattermost.yaml`)
  - Covers `*.cloud.mattermost.com` API v4 and webhook endpoints
  - Auto-detected when `MATTERMOST_TOKEN` or `MATTERMOST_URL` env vars are set

- **Bedrock provider label** in TypeScript config (`nemoclaw/src/onboard/config.ts`)
  - `"bedrock"` endpoint type → `"AWS Bedrock"` display label

- **Test coverage** for all new Bedrock functionality
  - `test/inference-config.test.js` — provider mapping, model options, primary model resolution
  - `nemoclaw/src/onboard/config.test.ts` — endpoint type label mapping

- **LiteLLM proxy for Bedrock** (`scripts/litellm-proxy.sh`) — Automatically started
  during Bedrock onboarding. Translates OpenAI-format requests from OpenShell into
  Bedrock Converse API calls, enabling Claude, Llama, Nova, and Mistral models
  (Bedrock's native OpenAI endpoint only supports GPT OSS models).
  - Runs on `127.0.0.1:4000`, managed via PID file
  - Config generated dynamically from AWS credentials
  - Integrated into `govclaw status` service display
  - Installed as a pip dependency during `govclaw-install.sh`

- **Dynamic Bedrock model discovery** — After entering API key and region, the
  setup script fetches available models from the Bedrock `ListFoundationModels`
  API and presents them as the model picker. Falls back to a hardcoded list if
  the API call fails.

- **Bedrock API key validation** — Credentials are tested immediately after entry
  by calling the Bedrock API. Catches expired/invalid keys before creating the
  sandbox, with option to re-enter.

### Fixed

- **Policy preset prompt ignoring user input** — Typing a preset name (e.g. "discord")
  at the `Apply suggested presets? [Y/n/list]:` prompt was treated as "yes" and applied
  the default suggestions (pypi, npm) instead. Now recognizes preset names typed directly
  and applies only those.
  - File: `bin/lib/onboard.js` (`setupPolicies` function)

### Changed

- `install.sh` — Updated `NEMOCLAW_PROVIDER` help text to include `bedrock`;
  added `AWS_BEARER_TOKEN_BEDROCK`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
  env var documentation.
- `test/policies.test.js` — Updated preset count (9 → 10) and name list to include `mattermost`.

### GovClaw Fork — Separate Files (no upstream modifications)

GovClaw branding lives in dedicated files to avoid merge conflicts
when pulling upstream NemoClaw changes:

- **`govclaw-install.sh`** — Standalone installer that sources `install.sh`
  and overrides `print_banner`, `print_done`, and `usage` with GovClaw
  branding. Run `bash govclaw-install.sh` instead of `bash install.sh`.
- **`bin/govclaw.js`** — CLI entrypoint with GovClaw help text. Intercepts
  `help`/`--version` for branding, delegates all other commands to
  `bin/nemoclaw.js`. Registered as `govclaw` binary in `package.json`.
- **`package.json`** — Name set to `govclaw`, adds `govclaw` bin entry
  pointing to `bin/govclaw.js`.
- **`nemoclaw/openclaw.plugin.json`** — Plugin id/name set to `govclaw`/`GovClaw`.
- **`nemoclaw/src/commands/slash.ts`** — Chat-facing messages show GovClaw branding.
- **`nemoclaw/src/index.ts`** — Plugin registration banner shows "GovClaw registered".
- **Upstream files untouched**: `install.sh`, `bin/nemoclaw.js`,
  `scripts/nemoclaw-start.sh` remain as-is from NemoClaw upstream.
