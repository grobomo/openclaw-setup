---
name: openclaw-setup
description: Install and configure OpenClaw AI assistant with guided setup, secure secret management, and repeatable automation
triggers:
  - install openclaw
  - setup openclaw
  - deploy openclaw
  - openclaw setup
  - configure openclaw
  - openclaw install
  - openclaw backup
  - openclaw restore
  - openclaw config backup
---

# OpenClaw Setup Skill

You help users install, configure, and maintain OpenClaw -- a self-hosted AI assistant
that connects to messaging platforms (Slack, Discord, Telegram, Signal, WhatsApp, etc.).

## What You Do

1. **Install OpenClaw** on macOS, Linux, or WSL2 (Windows)
2. **Interview the user** about their preferences:
   - Model provider (Anthropic, OpenAI, OpenRouter, custom endpoint, Ollama)
   - Which channels to connect (Slack, Discord, Telegram, Signal, etc.)
   - Guide them to get tokens (with links to official setup pages)
3. **Configure everything** using `openclaw config set` commands (NEVER edit JSON directly)
4. **Store secrets securely** in `~/.openclaw/.env` with proper permissions
5. **Pin trusted plugins** via `plugins.allow` to prevent untrusted auto-loading
6. **Verify the deployment** with `openclaw doctor` and `openclaw gateway status`
7. **Back up and restore config** with timestamped, validated snapshots
8. **Track all changes** in a local git repo for rollback capability

## Critical Rules

### Secret Safety
- NEVER store API keys, tokens, or passwords in `openclaw.json`
- ALWAYS use env var references: `${VAR_NAME}` in config, actual values in `~/.openclaw/.env`
- Set `chmod 600 ~/.openclaw/.env` and `chmod 700 ~/.openclaw/`
- Tell users to NEVER commit `.env` files to git

### Config Safety (Prevents the #1 OpenClaw Failure Mode)
- ALWAYS use `openclaw config set` to change configuration
- NEVER edit `openclaw.json` directly (agents corrupt JSON syntax -- Bug #6028)
- ALWAYS stop gateway before manual config edits: `openclaw gateway stop`
- Run `openclaw config validate` after any changes
- Run `openclaw doctor --fix` to catch schema drift

### Plugin Trust
- Set `plugins.allow` to an explicit list of trusted plugin IDs
- Prevents unknown plugins from auto-loading (the vector behind Bug #6028 crashes)
- In non-interactive mode: `OC_PLUGINS_ALLOW=coconut-guardrails,memory-core`

### Recovery
If config gets corrupted:
```bash
bash scripts/config-backup.sh restore <backup-file>            # restore validated backup
openclaw doctor --fix                                          # auto-repair
openclaw config validate                                       # verify
```

Config backup commands:
```bash
bash scripts/config-backup.sh backup     # timestamped snapshot with sha256
bash scripts/config-backup.sh list       # show available backups
bash scripts/config-backup.sh diff <f>   # compare backup vs current
bash scripts/config-backup.sh restore <f> # restore with pre-restore safety backup
```

## Setup Flow

```
1. Check Node.js 22.16+ installed
2. Install: npm install -g openclaw@latest
3. Onboard: openclaw onboard --install-daemon
4. Configure model provider via openclaw config set
5. Store API keys in ~/.openclaw/.env
6. Configure channels via openclaw config set
7. Store channel tokens in ~/.openclaw/.env
8. Start: openclaw gateway start
9. Verify: openclaw doctor && openclaw gateway status
```

## Automation Script

Interactive:
```bash
bash scripts/openclaw-setup.sh [--config config.env] [--skip-install] [--dry-run]
```

Non-interactive (CI/fleet):
```bash
OC_PROVIDER=1 OC_CHANNELS=slack OC_PLUGINS_ALLOW=memory-core,slack \
bash scripts/openclaw-setup.sh --non-interactive --skip-install
```

The script interviews the user (or reads env vars), stores secrets, pins trusted plugins, validates JSON, and verifies.

## Channel Token Guide

### Slack
1. Create app at https://api.slack.com/apps
2. Enable Socket Mode -> get App Token (xapp-...)
3. Add Bot Token Scopes: chat:write, channels:history, groups:history, im:history, users:read
4. Install to workspace -> get Bot Token (xoxb-...)
5. Store both in ~/.openclaw/.env

### Telegram
1. Message @BotFather on Telegram
2. /newbot -> follow prompts -> copy token
3. Store in ~/.openclaw/.env as TELEGRAM_BOT_TOKEN

### Discord
1. https://discord.com/developers/applications -> New Application
2. Bot section -> Reset Token -> copy
3. Enable Message Content Intent
4. Store in ~/.openclaw/.env as DISCORD_BOT_TOKEN

### Signal
- Uses signal-cli, no token needed
- Default pairing mode: unknown senders get a pairing code

## Reference
- [Official Docs](https://docs.openclaw.ai/start/getting-started)
- [Configuration Reference](https://docs.openclaw.ai/gateway/configuration)
- [Security Guide](https://www.freecodecamp.org/news/how-to-build-and-secure-a-personal-ai-agent-with-openclaw/)
- [Production Gotchas](https://kaxo.io/insights/openclaw-production-gotchas/)
