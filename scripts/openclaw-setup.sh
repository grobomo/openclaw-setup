#!/usr/bin/env bash
# openclaw-setup.sh -- Repeatable OpenClaw deployment script
# Cross-platform: macOS, Linux, WSL2 (Windows users run this in WSL)
#
# Usage:
#   bash scripts/openclaw-setup.sh [--config config.env] [--skip-install] [--dry-run] [--non-interactive]
#
# This script:
# 1. Checks prerequisites (Node.js, platform)
# 2. Installs OpenClaw if not present
# 3. Interviews user for preferences (model provider, channels, tokens)
# 4. Generates config via `openclaw config set` (never direct JSON edits)
# 5. Starts gateway and verifies
# 6. Logs every command to setup-log.md
#
# Non-interactive mode (--non-interactive):
#   Reads all config from env vars instead of prompting. Required env vars:
#     OC_PROVIDER       - Provider choice: 1=anthropic, 2=openai, 3=openrouter, 4=custom, 5=ollama (default: 1)
#     OC_MODEL          - Default model (default: anthropic/claude-sonnet-4-6)
#     OC_CHANNELS       - Comma-separated channels or "none" (default: none)
#     OC_PORT           - Gateway port (default: 18789)
#   For custom providers (OC_PROVIDER=4):
#     OC_PROVIDER_NAME  - Short name (default: custom)
#     OC_BASE_URL       - Provider base URL
#     OC_MODEL_ID       - Model ID
#     OC_AUTH_HEADER    - Use auth header (default: true)
#     OC_CONTEXT_WINDOW - Model context window size (default: 200000)
#     OC_MAX_TOKENS     - Model max output tokens (default: 64000)
#     OC_PLUGINS_ALLOW - Comma-separated plugin IDs to trust (default: empty = warn only)
#   API keys must be pre-set in ~/.openclaw/.env
#
# Secrets are stored in ~/.openclaw/.env (chmod 600), never in config files.
# Config changes are tracked via local git commits.

set -euo pipefail

# --- Constants ---
OPENCLAW_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"
OPENCLAW_ENV="$OPENCLAW_HOME/.env"
SETUP_LOG=""
DRY_RUN=false
SKIP_INSTALL=false
NON_INTERACTIVE=false
CONFIG_FILE=""
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- Parse args ---
while [[ $# -gt 0 ]]; do
  case $1 in
    --config) CONFIG_FILE="$2"; shift 2 ;;
    --skip-install) SKIP_INSTALL=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    --non-interactive) NON_INTERACTIVE=true; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# --- Logging ---
log() { echo -e "${GREEN}[openclaw-setup]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARNING]${NC} $*"; }
err() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
step() { echo -e "\n${BLUE}=== $* ===${NC}"; }

log_cmd() {
  # Log and execute a command. Arguments passed as separate words — no eval.
  local ts
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  if [[ -n "$SETUP_LOG" ]]; then
    echo "[$ts] $*" >> "$SETUP_LOG"
  fi
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "  [dry-run] $*"
  else
    "$@"
  fi
}

# --- Helpers ---
# Store or update a key=value in the .env file (dedup safe)
env_set() {
  local key="$1" value="$2"
  if [[ -f "$OPENCLAW_ENV" ]]; then
    grep -v "^${key}=" "$OPENCLAW_ENV" > "${OPENCLAW_ENV}.tmp" 2>/dev/null || true
    mv "${OPENCLAW_ENV}.tmp" "$OPENCLAW_ENV"
  fi
  echo "${key}=${value}" >> "$OPENCLAW_ENV"
}

# --- Prerequisites ---
check_prereqs() {
  step "Checking prerequisites"

  # Node.js
  if ! command -v node &>/dev/null; then
    err "Node.js not found. Install Node.js 24+ first."
    err "  macOS/Linux: curl -fsSL https://fnm.vercel.app/install | bash && fnm install 24"
    err "  Or: https://nodejs.org/en/download"
    exit 1
  fi

  local node_major
  node_major=$(node -e "console.log(process.versions.node.split('.')[0])")
  if [[ "$node_major" -lt 22 ]]; then
    err "Node.js $node_major found, but 22.16+ required (24 recommended)"
    exit 1
  fi
  log "Node.js $(node --version) OK"

  # Platform check
  local platform
  platform="$(uname -s)"
  case "$platform" in
    Linux*)  log "Platform: Linux/WSL" ;;
    Darwin*) log "Platform: macOS" ;;
    *)       warn "Untested platform: $platform. Proceed with caution." ;;
  esac

  # WSL check for Windows users
  if grep -qi microsoft /proc/version 2>/dev/null; then
    log "WSL detected (recommended for Windows)"
  fi
}

# --- Install ---
install_openclaw() {
  step "Installing OpenClaw"

  if command -v openclaw &>/dev/null; then
    local version
    version="$(openclaw --version 2>/dev/null || echo 'unknown')"
    log "OpenClaw already installed: $version"
    if [[ "$NON_INTERACTIVE" == "true" ]]; then
      log "Non-interactive: skipping reinstall prompt"
      return 0
    fi
    read -rp "Reinstall/update? [y/N]: " choice
    if [[ "$choice" != "y" && "$choice" != "Y" ]]; then
      return 0
    fi
  fi

  log "Installing OpenClaw via npm..."
  log_cmd npm install -g openclaw@latest
  log "Installed: $(openclaw --version)"
}

# --- Interview ---
# Collects user preferences and stores in variables.
# In non-interactive mode, reads from OC_* env vars instead of prompting.
interview_user() {
  step "Setup Preferences"

  if [[ "$NON_INTERACTIVE" == "true" ]]; then
    log "Non-interactive mode: reading config from OC_* environment variables"
    MODEL_CHOICE="${OC_PROVIDER:-1}"
    GW_PORT="${OC_PORT:-18789}"
    CHANNELS="${OC_CHANNELS:-none}"
  else
    echo "Answer these questions to configure your OpenClaw instance."
    echo "Press Enter to accept defaults shown in [brackets]."
    echo ""

    # Model provider
    echo "Model Provider Options:"
    echo "  1) Anthropic (direct API key)"
    echo "  2) OpenAI"
    echo "  3) OpenRouter"
    echo "  4) Custom OpenAI-compatible endpoint"
    echo "  5) Local model (Ollama)"
    read -rp "Choose model provider [1]: " MODEL_CHOICE
    MODEL_CHOICE="${MODEL_CHOICE:-1}"
  fi

  case "$MODEL_CHOICE" in
    1)
      PROVIDER_NAME="anthropic"
      PROVIDER_API="anthropic"
      API_KEY_ENV_NAME="$(echo "$PROVIDER_NAME" | tr '[:lower:]' '[:upper:]')_API_KEY"
      if [[ "$NON_INTERACTIVE" == "true" ]]; then
        DEFAULT_MODEL="${OC_MODEL:-anthropic/claude-sonnet-4-6}"
        API_KEY_VALUE=""
      else
        read -rp "Default model [anthropic/claude-sonnet-4-6]: " DEFAULT_MODEL
        DEFAULT_MODEL="${DEFAULT_MODEL:-anthropic/claude-sonnet-4-6}"
        echo ""
        echo "API Key Storage:"
        echo "  Your API key will be stored in ~/.openclaw/.env (chmod 600)"
        echo "  The config references it via env var"
        echo "  NEVER paste keys into openclaw.json directly"
        echo ""
        read -rsp "Paste your API key (hidden): " API_KEY_VALUE
        echo ""
      fi
      ;;
    2)
      PROVIDER_NAME="openai"
      PROVIDER_API="openai-completions"
      API_KEY_ENV_NAME="OPENAI_API_KEY"
      if [[ "$NON_INTERACTIVE" == "true" ]]; then
        DEFAULT_MODEL="${OC_MODEL:-openai/gpt-4o}"
        API_KEY_VALUE=""
      else
        read -rp "Default model [openai/gpt-4o]: " DEFAULT_MODEL
        DEFAULT_MODEL="${DEFAULT_MODEL:-openai/gpt-4o}"
        echo ""
        echo "API Key Storage:"
        echo "  Your API key will be stored in ~/.openclaw/.env (chmod 600)"
        echo ""
        read -rsp "Paste your OpenAI API key (hidden): " API_KEY_VALUE
        echo ""
      fi
      ;;
    3)
      PROVIDER_NAME="openrouter"
      PROVIDER_API="openai-completions"
      PROVIDER_BASE_URL="https://openrouter.ai/api/v1"
      API_KEY_ENV_NAME="OPENROUTER_API_KEY"
      if [[ "$NON_INTERACTIVE" == "true" ]]; then
        DEFAULT_MODEL="${OC_MODEL:-openrouter/anthropic/claude-sonnet-4-6}"
        API_KEY_VALUE=""
      else
        read -rp "Default model [openrouter/anthropic/claude-sonnet-4-6]: " DEFAULT_MODEL
        DEFAULT_MODEL="${DEFAULT_MODEL:-openrouter/anthropic/claude-sonnet-4-6}"
        echo ""
        echo "API Key Storage:"
        echo "  Your API key will be stored in ~/.openclaw/.env (chmod 600)"
        echo ""
        read -rsp "Paste your OpenRouter API key (hidden): " API_KEY_VALUE
        echo ""
      fi
      ;;
    4)
      PROVIDER_API="openai-completions"
      if [[ "$NON_INTERACTIVE" == "true" ]]; then
        PROVIDER_NAME="${OC_PROVIDER_NAME:-custom}"
        PROVIDER_BASE_URL="${OC_BASE_URL:?OC_BASE_URL required for custom provider}"
        DEFAULT_MODEL_ID="${OC_MODEL_ID:?OC_MODEL_ID required for custom provider}"
        DEFAULT_MODEL="${PROVIDER_NAME}/${DEFAULT_MODEL_ID}"
        AUTH_HEADER="${OC_AUTH_HEADER:-true}"
        API_KEY_VALUE=""
      else
        read -rp "Provider name (short, no spaces) [custom]: " PROVIDER_NAME
        PROVIDER_NAME="${PROVIDER_NAME:-custom}"
        read -rp "Base URL: " PROVIDER_BASE_URL
        read -rp "Default model ID: " DEFAULT_MODEL_ID
        DEFAULT_MODEL="${PROVIDER_NAME}/${DEFAULT_MODEL_ID}"
        read -rp "Auth header? [true]: " AUTH_HEADER
        AUTH_HEADER="${AUTH_HEADER:-true}"
        echo ""
        echo "API Key Storage:"
        echo "  Stored in ~/.openclaw/.env as \${$(echo "$PROVIDER_NAME" | tr '[:lower:]' '[:upper:]')_API_KEY}"
        echo ""
        read -rsp "Paste your API key (hidden): " API_KEY_VALUE
        echo ""
      fi
      API_KEY_ENV_NAME="$(echo "$PROVIDER_NAME" | tr '[:lower:]' '[:upper:]')_API_KEY"
      ;;
    5)
      PROVIDER_NAME="ollama"
      PROVIDER_API="openai-completions"
      PROVIDER_BASE_URL="http://localhost:11434/v1"
      if [[ "$NON_INTERACTIVE" == "true" ]]; then
        DEFAULT_MODEL_ID="${OC_MODEL_ID:-llama3.1:8b}"
      else
        read -rp "Model ID [llama3.1:8b]: " DEFAULT_MODEL_ID
        DEFAULT_MODEL_ID="${DEFAULT_MODEL_ID:-llama3.1:8b}"
      fi
      DEFAULT_MODEL="ollama/${DEFAULT_MODEL_ID}"
      API_KEY_VALUE=""
      API_KEY_ENV_NAME=""
      ;;
    *)
      err "Unsupported choice: $MODEL_CHOICE"
      exit 1
      ;;
  esac

  if [[ "$NON_INTERACTIVE" != "true" ]]; then
    # Gateway port
    read -rp "Gateway port [18789]: " GW_PORT
    GW_PORT="${GW_PORT:-18789}"

    # Channels
    echo ""
    echo "Available channels: slack, telegram, discord, signal, whatsapp, teams, webchat"
    read -rp "Which channels to enable (comma-separated, or 'none') [none]: " CHANNELS
    CHANNELS="${CHANNELS:-none}"
  fi

  # Channel tokens collected per-channel below
  CHANNEL_LIST=()
  if [[ "$CHANNELS" != "none" ]]; then
    IFS=',' read -ra CHANNEL_LIST <<< "$CHANNELS"
  fi
}

# --- Store secrets ---
store_secrets() {
  step "Storing secrets"

  mkdir -p "$OPENCLAW_HOME"
  chmod 700 "$OPENCLAW_HOME"

  # Create or update .env file
  if [[ -n "${API_KEY_VALUE:-}" && -n "${API_KEY_ENV_NAME:-}" ]]; then
    env_set "$API_KEY_ENV_NAME" "$API_KEY_VALUE"
    log "Stored $API_KEY_ENV_NAME in $OPENCLAW_ENV"
  fi

  # Collect and store channel tokens (skip in non-interactive — tokens must be pre-set in .env)
  if [[ "$NON_INTERACTIVE" == "true" ]]; then
    log "Non-interactive: skipping token prompts (tokens must be pre-set in $OPENCLAW_ENV)"
  else
    for ch in ${CHANNEL_LIST[@]+"${CHANNEL_LIST[@]}"}; do
      ch="$(echo "$ch" | xargs)"  # trim whitespace
      case "$ch" in
        slack)
          echo ""
          echo "Slack Setup:"
          echo "  1. Create a Slack app at https://api.slack.com/apps"
          echo "  2. Enable Socket Mode and get an App Token (xapp-...)"
          echo "  3. Install to workspace and get Bot Token (xoxb-...)"
          echo "  Tokens stored in ~/.openclaw/.env, referenced via \${VAR}"
          echo ""
          read -rsp "Slack Bot Token (xoxb-..., hidden): " SLACK_BOT
          echo ""
          read -rsp "Slack App Token (xapp-..., hidden): " SLACK_APP
          echo ""
          env_set "SLACK_BOT_TOKEN" "$SLACK_BOT"
          env_set "SLACK_APP_TOKEN" "$SLACK_APP"
          log "Stored Slack tokens"
          ;;
        telegram)
          echo ""
          echo "Telegram Setup:"
          echo "  1. Message @BotFather on Telegram"
          echo "  2. Send /newbot and follow prompts"
          echo "  3. Copy the bot token"
          echo ""
          read -rsp "Telegram Bot Token (hidden): " TG_TOKEN
          echo ""
          env_set "TELEGRAM_BOT_TOKEN" "$TG_TOKEN"
          log "Stored Telegram token"
          ;;
        discord)
          echo ""
          echo "Discord Setup:"
          echo "  1. Go to https://discord.com/developers/applications"
          echo "  2. Create application, add bot, copy token"
          echo "  3. Enable Message Content Intent"
          echo ""
          read -rsp "Discord Bot Token (hidden): " DC_TOKEN
          echo ""
          env_set "DISCORD_BOT_TOKEN" "$DC_TOKEN"
          log "Stored Discord token"
          ;;
        signal)
          log "Signal uses signal-cli (no token needed). Will configure pairing mode."
          ;;
        *)
          warn "Channel '$ch' not yet automated. Configure manually after setup."
          ;;
      esac
    done
  fi

  if [[ -f "$OPENCLAW_ENV" ]]; then
    chmod 600 "$OPENCLAW_ENV"
    log "Secrets file permissions set to 600"
  fi
}

# --- Configure ---
configure_openclaw() {
  step "Configuring OpenClaw"

  # Gateway
  log_cmd openclaw config set gateway.mode local
  log_cmd openclaw config set gateway.bind loopback
  log_cmd openclaw config set gateway.port "$GW_PORT"
  log_cmd openclaw config set gateway.auth.mode token
  log_cmd openclaw config set gateway.http.endpoints.chatCompletions.enabled true

  # Model provider
  case "$MODEL_CHOICE" in
    1)
      log_cmd openclaw config set agents.defaults.model.primary "$DEFAULT_MODEL"
      ;;
    2)
      # OpenAI: simple provider with API key from env
      log_cmd openclaw config set models.mode merge
      log_cmd openclaw config set models.providers.openai --json \
        "{\"apiKey\":\"\${OPENAI_API_KEY}\",\"api\":\"openai-completions\"}"
      log_cmd openclaw config set agents.defaults.model.primary "$DEFAULT_MODEL"
      ;;
    3)
      # OpenRouter: OpenAI-compatible with custom base URL
      log_cmd openclaw config set models.mode merge
      log_cmd openclaw config set models.providers.openrouter --json \
        "{\"baseUrl\":\"${PROVIDER_BASE_URL}\",\"apiKey\":\"\${OPENROUTER_API_KEY}\",\"api\":\"openai-completions\",\"authHeader\":true}"
      log_cmd openclaw config set agents.defaults.model.primary "$DEFAULT_MODEL"
      ;;
    4)
      # T017: Set provider atomically with --json to avoid validation errors
      local ctx_window="${OC_CONTEXT_WINDOW:-200000}"
      local max_tokens="${OC_MAX_TOKENS:-64000}"
      log_cmd openclaw config set models.mode merge
      log_cmd openclaw config set "models.providers.${PROVIDER_NAME}" --json \
        "{\"baseUrl\":\"${PROVIDER_BASE_URL}\",\"apiKey\":\"\${${API_KEY_ENV_NAME}}\",\"api\":\"${PROVIDER_API}\",\"authHeader\":${AUTH_HEADER},\"models\":[{\"id\":\"${DEFAULT_MODEL_ID}\",\"name\":\"${DEFAULT_MODEL_ID}\",\"reasoning\":true,\"input\":[\"text\",\"image\"],\"contextWindow\":${ctx_window},\"maxTokens\":${max_tokens}}]}"
      log_cmd openclaw config set agents.defaults.model.primary "$DEFAULT_MODEL"
      ;;
    5)
      # T017: Set Ollama provider atomically
      log_cmd openclaw config set models.mode merge
      log_cmd openclaw config set models.providers.ollama --json \
        "{\"baseUrl\":\"${PROVIDER_BASE_URL}\",\"api\":\"${PROVIDER_API}\",\"models\":[{\"id\":\"${DEFAULT_MODEL_ID}\",\"name\":\"${DEFAULT_MODEL_ID}\",\"reasoning\":false,\"input\":[\"text\"],\"contextWindow\":128000,\"maxTokens\":32000}]}"
      log_cmd openclaw config set agents.defaults.model.primary "$DEFAULT_MODEL"
      ;;
  esac

  # Agent defaults
  log_cmd openclaw config set agents.defaults.timeoutSeconds 300
  log_cmd openclaw config set agents.defaults.compaction.mode safeguard
  log_cmd openclaw config set agents.defaults.compaction.notifyUser true

  # Channels
  for ch in ${CHANNEL_LIST[@]+"${CHANNEL_LIST[@]}"}; do
    ch="$(echo "$ch" | xargs)"
    case "$ch" in
      slack)
        log_cmd openclaw config set channels.slack.enabled true
        log_cmd openclaw config set channels.slack.mode socket
        log_cmd openclaw config set channels.slack.dmPolicy allowlist
        log_cmd openclaw config set channels.slack.botToken '${SLACK_BOT_TOKEN}'
        log_cmd openclaw config set channels.slack.appToken '${SLACK_APP_TOKEN}'
        log_cmd openclaw config set channels.slack.groupPolicy mention
        ;;
      telegram)
        log_cmd openclaw config set channels.telegram.enabled true
        log_cmd openclaw config set channels.telegram.token '${TELEGRAM_BOT_TOKEN}'
        log_cmd openclaw config set channels.telegram.dmPolicy pairing
        ;;
      discord)
        log_cmd openclaw config set channels.discord.enabled true
        log_cmd openclaw config set channels.discord.token '${DISCORD_BOT_TOKEN}'
        log_cmd openclaw config set channels.discord.dmPolicy pairing
        ;;
      signal)
        log_cmd openclaw config set channels.signal.enabled true
        log_cmd openclaw config set channels.signal.dmPolicy pairing
        log_cmd openclaw config set channels.signal.autoStart true
        ;;
    esac
  done

  # Security hardening
  log_cmd openclaw config set logging.level info
  log_cmd openclaw config set logging.redactSensitive on

  # T068: Pin trusted plugins via plugins.allow — prevents untrusted auto-loading
  pin_plugin_trust

  # T046: Pre-flight JSON validation — catch brace mismatches before gateway start
  validate_config
}

# --- Plugin Trust Pinning (T068) ---
pin_plugin_trust() {
  local plugins_allow=""

  if [[ "$DRY_RUN" == "true" ]]; then
    log "  [dry-run] pin_plugin_trust — would detect and pin installed plugins"
    return 0
  fi

  if [[ "$NON_INTERACTIVE" == "true" ]]; then
    # T069: Non-interactive mode uses OC_PLUGINS_ALLOW env var
    plugins_allow="${OC_PLUGINS_ALLOW:-}"
    if [[ -z "$plugins_allow" ]]; then
      log "OC_PLUGINS_ALLOW not set — skipping plugin trust pinning"
      warn "plugins.allow is empty; discovered plugins will auto-load without trust verification"
      return 0
    fi
  else
    # Interactive: detect installed plugins via extension directory (most reliable)
    local discovered=""
    local ext_dir="$OPENCLAW_HOME/extensions"
    if [[ -d "$ext_dir" ]]; then
      discovered="$(ls -1 "$ext_dir" 2>/dev/null | tr '\n' ',' | sed 's/,$//')" || true
    fi

    if [[ -z "$discovered" ]]; then
      # Fallback: parse top-level keys from plugins.entries JSON (2-space indent = top-level)
      discovered="$(openclaw config get plugins.entries 2>/dev/null | sed -n 's/^  "\([^"]*\)"[[:space:]]*:.*/\1/p' | tr '\n' ',' | sed 's/,$//')" || true
    fi

    if [[ -z "$discovered" ]]; then
      log "No plugins discovered — skipping trust pinning"
      return 0
    fi

    echo ""
    echo "Plugin Trust Pinning:"
    echo "  Discovered plugins: $discovered"
    echo "  Setting plugins.allow pins trusted plugins explicitly."
    echo "  Untrusted plugins will NOT auto-load."
    echo ""
    read -rp "Plugins to trust (comma-separated, or 'all' for above, or 'none') [$discovered]: " plugins_allow
    plugins_allow="${plugins_allow:-$discovered}"

    if [[ "$plugins_allow" == "none" ]]; then
      log "Skipping plugin trust pinning"
      return 0
    fi
    if [[ "$plugins_allow" == "all" ]]; then
      plugins_allow="$discovered"
    fi
  fi

  # Set plugins.allow as JSON array
  local json_array="["
  local first=true
  IFS=',' read -ra plugin_ids <<< "$plugins_allow"
  for pid in "${plugin_ids[@]}"; do
    pid="$(echo "$pid" | xargs)"  # trim whitespace
    if [[ -z "$pid" ]]; then continue; fi
    if [[ "$first" == "true" ]]; then
      json_array+="\"$pid\""
      first=false
    else
      json_array+=",\"$pid\""
    fi
  done
  json_array+="]"

  log_cmd openclaw config set plugins.allow --json "$json_array"
  log "Pinned trusted plugins: $plugins_allow"
}

# --- Config Validation (T046) ---
validate_config() {
  local config_file="$OPENCLAW_HOME/openclaw.json"
  if [[ "$DRY_RUN" == "true" ]]; then
    log "  [dry-run] validate_config $config_file"
    return 0
  fi
  if [[ ! -f "$config_file" ]]; then
    return 0
  fi

  # Use node (already required) to validate JSON structure
  if ! node -e "JSON.parse(require('fs').readFileSync('$config_file','utf8'))" 2>/dev/null; then
    err "openclaw.json has invalid JSON structure!"
    err "This can happen when config edits introduce mismatched braces."
    err "Backup at: ${config_file}.bak"
    err "Fix: restore from backup, then use 'openclaw config set' (not direct edits)"
    return 1
  fi

  log "Config JSON structure validated"
}

# --- Start & Verify ---
start_and_verify() {
  step "Starting Gateway"

  # Auth Claude CLI if using Anthropic
  if [[ "$MODEL_CHOICE" == "1" ]]; then
    log "Setting up Claude CLI auth for OpenClaw..."
    log_cmd openclaw models auth login --provider anthropic --method cli --set-default
  fi

  # Fix any issues found by doctor
  log "Running doctor --fix..."
  log_cmd openclaw doctor --fix || true

  # Start gateway
  log_cmd openclaw gateway start

  if [[ "$DRY_RUN" != "true" ]]; then
    # Wait for gateway to be ready
    log "Waiting for gateway..."
    local retries=10
    while [[ $retries -gt 0 ]]; do
      if openclaw gateway status 2>/dev/null | grep -q "running"; then
        break
      fi
      sleep 2
      ((retries--))
    done
  fi

  step "Verification"
  log_cmd openclaw gateway status
  log_cmd openclaw doctor
  log_cmd openclaw config validate

  if [[ ${#CHANNEL_LIST[@]} -gt 0 ]]; then
    log_cmd openclaw channel list
  fi
}

# --- Post-setup ---
post_setup() {
  step "Post-Setup"

  log "Setup complete!"
  echo ""
  echo "Summary:"
  echo "  Gateway: http://127.0.0.1:${GW_PORT}/"
  echo "  Dashboard: openclaw dashboard"
  echo "  Config: ~/.openclaw/openclaw.json"
  echo "  Secrets: ~/.openclaw/.env (chmod 600)"
  echo ""
  echo "Recommended next steps:"
  echo "  1. Run 'openclaw dashboard' to access the web UI"
  echo "  2. Send a test message to verify the AI responds"
  echo "  3. Review SOUL.md to customize the agent personality"
  echo "  4. Run 'openclaw security audit --deep' for security check"
  echo ""
  echo "Config management (ALWAYS use CLI, never edit JSON directly):"
  echo "  openclaw config set <path> <value>"
  echo "  openclaw config get <path>"
  echo "  openclaw doctor --fix"
  echo ""
  warn "NEVER edit openclaw.json while the gateway is running!"
  warn "NEVER store API keys in config files -- use ~/.openclaw/.env"
}

# --- Main ---
main() {
  log "OpenClaw Setup Script v1.0"
  mkdir -p "$PROJECT_DIR/docs"
  SETUP_LOG="$PROJECT_DIR/docs/setup-log-$(date +%Y%m%d-%H%M%S).log"
  log "Logging commands to: $SETUP_LOG"

  # Load config file if provided
  if [[ -n "$CONFIG_FILE" && -f "$CONFIG_FILE" ]]; then
    log "Loading config from $CONFIG_FILE"
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
  fi

  check_prereqs

  if [[ "$SKIP_INSTALL" == "false" ]]; then
    install_openclaw
  fi

  interview_user
  store_secrets
  configure_openclaw
  start_and_verify
  post_setup
}

main "$@"
