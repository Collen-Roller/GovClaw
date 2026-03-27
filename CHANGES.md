# GovClaw Changes

GovClaw is a government-focused fork of [NemoClaw](https://github.com/NVIDIA/NemoClaw),
adding features for secure AI agent sandboxing in government and defense environments.

---

## Unreleased — 2026-03-27

### Added

- **AWS Bedrock inference provider** — New option 3 in the setup script.
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

### Rebranding — GovClaw Fork

- **Package identity**: `package.json` name changed from `nemoclaw` to `govclaw`
- **CLI binary**: Added `govclaw` as primary CLI command (alongside `nemoclaw` for compat)
- **ASCII banner**: New GOVCLAW banner in `install.sh`, tagline updated
- **Installer messages**: All user-facing strings updated (step headers, runtime messages,
  help text, version output)
- **CLI help**: `bin/nemoclaw.js` — all command examples now show `govclaw <cmd>`
- **Plugin identity**: `openclaw.plugin.json` — id/name changed to `govclaw`/`GovClaw`
- **Slash commands**: All chat-facing text in `nemoclaw/src/commands/slash.ts` updated
  (status, onboard, eject messages)
- **Plugin registration**: Banner log shows "GovClaw registered"
- **Sandbox start script**: Boot message updated to "Setting up GovClaw..."
- **Internal paths preserved**: `~/.nemoclaw/` config dir, gateway name `nemoclaw`,
  and TypeScript interface names (e.g. `NemoClawOnboardConfig`) kept for backward
  compatibility with existing installations
