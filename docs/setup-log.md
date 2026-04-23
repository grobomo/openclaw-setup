# OpenClaw Setup Log

All commands and config changes during OpenClaw deployment, timestamped for reproducibility.

## 2026-04-23: Fresh Setup (Post-Config Corruption Recovery)

### Context
- OpenClaw installed and running since ~2026-04-14
- Agent corrupted `openclaw.json` by removing a closing brace from `agents.defaults`
- This nested `channels` inside `agents`, breaking JSON validation
- Backed up config to `openclaw.json.bak_04232026`, removed original
- Ran `openclaw onboard` but config still missing (onboard requires gateway.mode)

### Pre-existing State
```
OpenClaw version: 2026.4.14 (323493f)
Node.js: v24.13.0 (via nvm in WSL)
Install path: /usr/bin/openclaw
Config path: ~/.openclaw/openclaw.json (MISSING - moved to .bak)
Gateway: stopped (exit code 78 - missing config)
Daemon: systemd user service (openclaw-gateway.service)
```

### Previous Config Structure (from backup analysis)
- **Gateway**: local mode, loopback bind, port 18789, token auth, chatCompletions endpoint
- **Models**: Trend Micro AI Endpoint (RDSEC) with claude-4.6-sonnet/opus, claude-4.5-haiku
- **API Key**: via `${RDSEC_API_KEY}` env var substitution (good practice)
- **Channels**: Signal (pairing mode), Slack (allowlist + 9 channels, requireMention in threads)
- **Plugins**: coconut-guardrails, hook-runner-gates, mfa-skill-guard, cron-enforce, active-memory
- **MCP**: mcp-manager
- **Hooks**: heartbeat-enforce, channel-topic-inject/guard, session-start-reminder, hook-runner

### Root Cause of Corruption
The backup file has a missing `}` closing brace for `agents.defaults`:
```json
    "compaction": {
      "mode": "safeguard",
      "notifyUser": true
    }
  },          // <-- closes agents, NOT defaults (missing } for defaults)
  "channels": // <-- now nested inside agents instead of root
```
The agent likely edited the config directly instead of using `openclaw config set`.

### Doctor Output (pre-setup)
1. gateway.mode is unset - blocked gateway start
2. Claude CLI auth profile missing (anthropic:claude-cli)
3. Gateway auth off/missing token
4. Bundled plugin deps missing (@discordjs/opus)
5. Orphan agent directory: isolated
6. Other services detected: recording-watcher, teams-poller

### Recovery Steps

#### Step 1: Set Gateway Mode
```bash
openclaw config set gateway.mode local
```

#### Step 2: Configure Gateway
```bash
openclaw config set gateway.bind loopback
openclaw config set gateway.port 18789
openclaw config set gateway.auth.mode token
openclaw config set gateway.http.endpoints.chatCompletions.enabled true
```

#### Step 3: Configure Model Provider (Trend Micro AI Endpoint)
```bash
openclaw config set models.mode merge
openclaw config set models.providers.trendmicro-aiendpoint.baseUrl \
  "https://api.rdsec.trendmicro.com/prod/aiendpoint/v1"
openclaw config set models.providers.trendmicro-aiendpoint.api "openai-completions"
openclaw config set models.providers.trendmicro-aiendpoint.authHeader true
openclaw config set models.providers.trendmicro-aiendpoint.apiKey '${RDSEC_API_KEY}'
```

#### Step 4: Set Default Model
```bash
openclaw config set agents.defaults.model.primary "trendmicro-aiendpoint/claude-4.6-sonnet"
```

#### Step 5: Auth Claude CLI
```bash
openclaw models auth login --provider anthropic --method cli --set-default
```

#### Step 6: Install Missing Plugin Deps
```bash
openclaw doctor --fix
```

#### Step 7: Start Gateway
```bash
openclaw gateway start
openclaw gateway status
openclaw doctor
```

#### Step 8: Re-add Channels (post-gateway start)
```bash
# Slack channel config
openclaw config set channels.slack.enabled true
openclaw config set channels.slack.mode socket
openclaw config set channels.slack.name coconut
openclaw config set channels.slack.dmPolicy allowlist
openclaw config set channels.slack.botToken '${SLACK_BOT_TOKEN}'
openclaw config set channels.slack.appToken '${SLACK_APP_TOKEN}'
openclaw config set channels.slack.groupPolicy open

# Signal channel config
openclaw config set channels.signal.enabled true
openclaw config set channels.signal.dmPolicy pairing
openclaw config set channels.signal.autoStart true
```

#### Step 9: Verify Everything
```bash
openclaw gateway status     # should show running
openclaw doctor             # should show no critical issues
openclaw config validate    # should pass
openclaw channel list       # should show slack, signal
```

## Config Change Tracking

All config changes tracked here AND via git commits in this repo.
Run `git log --oneline` to see full history.

## Environment Files
- `~/.openclaw/.env` -- contains RDSEC_API_KEY, SLACK_BOT_TOKEN, SLACK_APP_TOKEN
- Permissions: `chmod 600 ~/.openclaw/.env`
- NEVER commit .env files or plaintext secrets
