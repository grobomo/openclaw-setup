# OpenClaw Research Notes

## Sources
- [Official Getting Started](https://docs.openclaw.ai/start/getting-started)
- [Official Configuration Reference](https://docs.openclaw.ai/gateway/configuration)
- [GitHub README](https://github.com/openclaw/openclaw)
- [FreeCodeCamp Security Guide](https://www.freecodecamp.org/news/how-to-build-and-secure-a-personal-ai-agent-with-openclaw/)
- [Production Gotchas (Kaxo)](https://kaxo.io/insights/openclaw-production-gotchas/)
- [Config Corruption Bug #6028](https://github.com/openclaw/openclaw/issues/6028)
- [Config Overwrite Bug #11355](https://github.com/openclaw/openclaw/issues/11355)

## Architecture

OpenClaw is a three-layer system:
1. **Channel Layer**: WhatsApp, Telegram, Slack, Discord, Signal, iMessage, Teams, WebChat, etc.
2. **Brain Layer**: Agent instructions (SOUL.md), model connections, routing
3. **Body Layer**: Tools, browser automation, file access, memory

The **Gateway** is the local control plane managing sessions, channels, tools, and events.

## Installation

### Prerequisites
- Node.js 24 (recommended) or Node 22.16+
- 8GB RAM minimum, 16GB+ for local models
- WSL2 recommended for Windows

### Install Commands
```bash
# macOS/Linux
curl -fsSL https://openclaw.ai/install.sh | bash

# Windows PowerShell
iwr -useb https://openclaw.ai/install.ps1 | iex

# npm (alternative)
npm install -g openclaw@latest
```

### Onboarding
```bash
openclaw onboard --install-daemon
```
Configures: gateway mode, model auth, workspace, optional channels. ~2 minutes.

### Verify
```bash
openclaw gateway status
openclaw doctor
```

## Configuration

### File Location
- `~/.openclaw/openclaw.json` (JSON5 format - supports comments and trailing commas)
- Override with `OPENCLAW_CONFIG_PATH` env var

### Config Editing Methods (SAFEST TO RISKIEST)
1. `openclaw config set <path> <value>` -- CLI one-liners (recommended)
2. `openclaw onboard` / `openclaw configure` -- interactive wizard
3. Dashboard UI at http://127.0.0.1:18789 Config tab
4. Direct file edit -- **STOP GATEWAY FIRST** or changes vanish

### Key Config Sections
- `gateway` -- port, bind, auth, http endpoints
- `models` -- provider definitions with baseUrl, apiKey, model specs
- `agents` -- defaults (model, workspace, skills), agent list
- `channels` -- per-provider config (enabled, dmPolicy, allowFrom, groups)
- `plugins` -- entries, load paths, installs
- `hooks` -- internal hook toggles
- `mcp` -- MCP server definitions

### Environment Variables
- `OPENCLAW_HOME` -- custom home directory
- `OPENCLAW_STATE_DIR` -- state directory
- `OPENCLAW_CONFIG_PATH` -- config file path
- Env files: `.env` in CWD, `~/.openclaw/.env`
- Config supports `${VAR_NAME}` substitution (uppercase only)
- Secret references: `{ "source": "env|file|exec", "provider": "default", "id": "KEY_NAME" }`

## Known Issues & Gotchas

### CRITICAL: Config Corruption (Bug #6028)
- **Problem**: Agents can modify their own config, breaking JSON syntax
- **Our experience**: Agent removed a closing brace from `agents.defaults`, nesting `channels` inside `agents`
- **Prevention**: Use `openclaw config set` instead of direct edits; keep backups

### CRITICAL: Gateway Race Condition
- **Problem**: Editing config while gateway runs = changes vanish
- **Fix**: ALWAYS stop gateway before editing, then restart

### Config Drift Across 4 Model Stores
- Config, session state, cron payloads, and model allowlist can drift
- **Fix**: Patch all stores atomically, restart after

### Agents Modifying Own Config
- Autonomous agents can hallucinate and write to config
- **Fix**: `chmod 444` on workspace files; `chmod 644` on gateway-managed files

### Upgrade-Induced Schema Changes
- Config keys silently become invalid after updates
- **Fix**: Snapshot `~/.openclaw/` before upgrading; run `openclaw doctor --fix` after

### Hot Reload Silent Failures
- Invalid keys prevent hot reload without errors
- **Fix**: `openclaw doctor --fix` to identify invalid keys

## Security Hardening Checklist

1. Bind to localhost: `gateway.bind: "loopback"`
2. Token auth: `gateway.auth.mode: "token"` with strong random token
3. File permissions: `chmod 700 ~/.openclaw`, `chmod 600 openclaw.json`
4. DM policy: Use `pairing` or `allowlist`, never `open`
5. Group chat: Set `requireMention: true`
6. Prompt injection defense: Add rules to AGENTS.md
7. Secrets via env vars: Use `${VAR_NAME}` in config, never plaintext
8. Security audit: `openclaw security audit --deep`

## Recovery Procedures

### Config Corrupted
```bash
openclaw doctor --fix
cp ~/.openclaw/openclaw.json.bak ~/.openclaw/openclaw.json
openclaw config validate
```

### Gateway Won't Start
```bash
openclaw doctor
openclaw gateway status
journalctl --user -u openclaw-gateway.service -n 200 --no-pager
```

## CLI Quick Reference

| Command | Purpose |
|---------|---------|
| `openclaw onboard --install-daemon` | First-time setup |
| `openclaw gateway start/stop/restart/status` | Gateway lifecycle |
| `openclaw doctor [--fix]` | Diagnose/fix issues |
| `openclaw config get/set/unset <path>` | Config management |
| `openclaw channel add/remove/list/status` | Channel management |
| `openclaw models auth login --provider X` | Model auth setup |
| `openclaw security audit --deep` | Security audit |
| `openclaw dashboard` | Open web UI |

## Supported Channels
WhatsApp, Telegram, Slack, Discord, Google Chat, Signal, iMessage, BlueBubbles, IRC, Microsoft Teams, Matrix, Feishu, LINE, Mattermost, Nextcloud Talk, Nostr, Synology Chat, Tlon, Twitch, Zalo, WeChat, QQ, WebChat
