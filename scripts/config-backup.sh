#!/usr/bin/env bash
# config-backup.sh — Snapshot openclaw.json with metadata
# Usage:
#   bash scripts/config-backup.sh [backup|restore|diff|list]
#
# Backups are stored in ~/.openclaw/backups/ as timestamped JSON files
# with a metadata wrapper (timestamp, hash, gateway status).
#
# This exists because a corrupted openclaw.json caused a 12-hour outage
# (2026-04-22). The rebuild from scratch lost days of advanced config.

set -euo pipefail

OPENCLAW_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"
CONFIG_FILE="$OPENCLAW_HOME/openclaw.json"
BACKUP_DIR="$OPENCLAW_HOME/backups"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[config-backup]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARNING]${NC} $*"; }
err() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# --- Backup ---
do_backup() {
  if [[ ! -f "$CONFIG_FILE" ]]; then
    err "No config found at $CONFIG_FILE"
    return 1
  fi

  # Validate JSON before backing up
  if ! node -e "JSON.parse(require('fs').readFileSync('$CONFIG_FILE','utf8'))" 2>/dev/null; then
    err "Current config has invalid JSON — refusing to backup corrupt config"
    err "Fix the config first, then backup"
    return 1
  fi

  mkdir -p "$BACKUP_DIR"
  local ts
  ts="$(date +%Y%m%d-%H%M%S)"
  local hash
  hash="$(sha256sum "$CONFIG_FILE" | cut -d' ' -f1)"
  local size
  size="$(wc -c < "$CONFIG_FILE")"
  local backup_file="$BACKUP_DIR/openclaw-${ts}.json"

  # Count top-level keys for summary
  local keys
  keys="$(node -e "const d=JSON.parse(require('fs').readFileSync('$CONFIG_FILE','utf8'));console.log(Object.keys(d).join(', '))" 2>/dev/null)"

  # Create backup with metadata header
  node -e "
    const config = JSON.parse(require('fs').readFileSync('$CONFIG_FILE', 'utf8'));
    const backup = {
      _backup: {
        timestamp: '$(date -u +%Y-%m-%dT%H:%M:%SZ)',
        sha256: '$hash',
        bytes: $size,
        hostname: require('os').hostname(),
        source: '$CONFIG_FILE'
      },
      config: config
    };
    require('fs').writeFileSync('$backup_file', JSON.stringify(backup, null, 2));
  "

  log "Backup saved: $backup_file"
  log "  Hash: ${hash:0:16}..."
  log "  Size: $size bytes"
  log "  Keys: $keys"
}

# --- Restore ---
do_restore() {
  local backup_file="${1:-}"
  if [[ -z "$backup_file" ]]; then
    # Use most recent backup
    backup_file="$(ls -t "$BACKUP_DIR"/openclaw-*.json 2>/dev/null | head -1)"
    if [[ -z "$backup_file" ]]; then
      err "No backups found in $BACKUP_DIR"
      return 1
    fi
    log "Using most recent backup: $(basename "$backup_file")"
  fi

  if [[ ! -f "$backup_file" ]]; then
    err "Backup file not found: $backup_file"
    return 1
  fi

  # Validate backup JSON
  if ! node -e "JSON.parse(require('fs').readFileSync('$backup_file','utf8'))" 2>/dev/null; then
    err "Backup file has invalid JSON"
    return 1
  fi

  # Extract config from backup wrapper
  local has_wrapper
  has_wrapper="$(node -e "const d=JSON.parse(require('fs').readFileSync('$backup_file','utf8'));console.log(d._backup?'yes':'no')" 2>/dev/null)"

  # Validate the config portion
  local config_valid
  if [[ "$has_wrapper" == "yes" ]]; then
    config_valid="$(node -e "
      const d=JSON.parse(require('fs').readFileSync('$backup_file','utf8'));
      try { JSON.stringify(d.config); console.log('yes'); } catch(e) { console.log('no'); }
    " 2>/dev/null)"
  else
    config_valid="yes"  # Raw config file, already validated above
  fi

  if [[ "$config_valid" != "yes" ]]; then
    err "Backup config section is invalid"
    return 1
  fi

  # Backup current config before overwriting
  if [[ -f "$CONFIG_FILE" ]]; then
    local pre_restore="$BACKUP_DIR/pre-restore-$(date +%Y%m%d-%H%M%S).json"
    cp "$CONFIG_FILE" "$pre_restore"
    log "Current config saved to: $(basename "$pre_restore")"
  fi

  # Restore
  if [[ "$has_wrapper" == "yes" ]]; then
    node -e "
      const d=JSON.parse(require('fs').readFileSync('$backup_file','utf8'));
      require('fs').writeFileSync('$CONFIG_FILE', JSON.stringify(d.config, null, 2));
    "
  else
    cp "$backup_file" "$CONFIG_FILE"
  fi

  # Final validation
  if ! node -e "JSON.parse(require('fs').readFileSync('$CONFIG_FILE','utf8'))" 2>/dev/null; then
    err "Restored config is invalid — something went wrong"
    if [[ -f "$pre_restore" ]]; then
      cp "$pre_restore" "$CONFIG_FILE"
      err "Rolled back to previous config"
    fi
    return 1
  fi

  local size
  size="$(wc -c < "$CONFIG_FILE")"
  log "Restored from: $(basename "$backup_file")"
  log "  Size: $size bytes"
  warn "Run 'openclaw gateway restart' to apply changes"
}

# --- Diff ---
do_diff() {
  local backup_file="${1:-}"
  if [[ -z "$backup_file" ]]; then
    backup_file="$(ls -t "$BACKUP_DIR"/openclaw-*.json 2>/dev/null | head -1)"
    if [[ -z "$backup_file" ]]; then
      err "No backups found in $BACKUP_DIR"
      return 1
    fi
  fi

  if [[ ! -f "$backup_file" ]]; then
    err "Backup file not found: $backup_file"
    return 1
  fi

  # Extract config from wrapper if needed, then diff top-level keys
  node -e "
    const fs = require('fs');
    const current = JSON.parse(fs.readFileSync('$CONFIG_FILE', 'utf8'));
    const backup = JSON.parse(fs.readFileSync('$backup_file', 'utf8'));
    const backupConfig = backup._backup ? backup.config : backup;

    const curKeys = new Set(Object.keys(current));
    const bakKeys = new Set(Object.keys(backupConfig));

    const added = [...curKeys].filter(k => !bakKeys.has(k));
    const removed = [...bakKeys].filter(k => !curKeys.has(k));
    const common = [...curKeys].filter(k => bakKeys.has(k));

    console.log('Comparing: current vs ' + '$(basename "$backup_file")');
    console.log('');
    if (added.length) console.log('Added:   ' + added.join(', '));
    if (removed.length) console.log('Removed: ' + removed.join(', '));
    console.log('');

    for (const k of common) {
      const a = JSON.stringify(current[k]);
      const b = JSON.stringify(backupConfig[k]);
      if (a !== b) {
        const aSize = a.length;
        const bSize = b.length;
        console.log('Changed: ' + k + ' (' + bSize + ' -> ' + aSize + ' chars)');
      }
    }
  "
}

# --- List ---
do_list() {
  if [[ ! -d "$BACKUP_DIR" ]]; then
    log "No backups directory yet. Run 'backup' to create one."
    return 0
  fi

  local count
  count="$(ls "$BACKUP_DIR"/openclaw-*.json 2>/dev/null | wc -l)"
  if [[ "$count" -eq 0 ]]; then
    log "No backups found."
    return 0
  fi

  log "$count backup(s) in $BACKUP_DIR:"
  for f in "$BACKUP_DIR"/openclaw-*.json; do
    local size
    size="$(wc -c < "$f")"
    local ts
    ts="$(node -e "
      const d=JSON.parse(require('fs').readFileSync('$f','utf8'));
      console.log(d._backup ? d._backup.timestamp : 'raw');
    " 2>/dev/null)"
    echo "  $(basename "$f")  ${size} bytes  $ts"
  done
}

# --- Main ---
case "${1:-backup}" in
  backup)  do_backup ;;
  restore) do_restore "${2:-}" ;;
  diff)    do_diff "${2:-}" ;;
  list)    do_list ;;
  *)
    echo "Usage: $0 [backup|restore|diff|list] [file]"
    echo ""
    echo "  backup          Snapshot current openclaw.json (default)"
    echo "  restore [file]  Restore from backup (latest if no file given)"
    echo "  diff [file]     Compare current config with backup"
    echo "  list            Show all backups"
    exit 1
    ;;
esac
