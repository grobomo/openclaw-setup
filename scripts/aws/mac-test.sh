#!/usr/bin/env bash
# mac-test.sh — Run E2E tests on dedicated AWS Mac instance via SSM
# Usage:
#   bash scripts/aws/mac-test.sh info       # Show instance details
#   bash scripts/aws/mac-test.sh test       # Run full E2E test suite
#   bash scripts/aws/mac-test.sh report     # Run tests and save report to reports/

set -euo pipefail

INSTANCE_ID="i-03b1aa541596068c9"
INSTANCE_NAME="mac-ztsa-test"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPORT_DIR="$SCRIPT_DIR/../../reports"
REMOTE_SCRIPT="$SCRIPT_DIR/mac-remote-test.sh"

ssm_exec() {
  # Execute commands on the Mac via SSM. Takes a JSON array of command strings.
  local COMMANDS_JSON="$1"
  local TIMEOUT="${2:-600}"

  local CMD_ID
  CMD_ID=$(aws ssm send-command \
    --instance-ids "$INSTANCE_ID" \
    --document-name "AWS-RunShellScript" \
    --parameters "{\"commands\":$COMMANDS_JSON,\"executionTimeout\":[\"$TIMEOUT\"]}" \
    --timeout-seconds "$TIMEOUT" \
    --query 'Command.CommandId' --output text 2>/dev/null)

  if [[ -z "$CMD_ID" || "$CMD_ID" == "None" ]]; then
    echo "ERROR: Failed to send SSM command" >&2
    return 1
  fi

  # Poll for completion
  local STATUS="InProgress"
  while [[ "$STATUS" == "InProgress" || "$STATUS" == "Pending" ]]; do
    sleep 5
    STATUS=$(aws ssm get-command-invocation \
      --command-id "$CMD_ID" \
      --instance-id "$INSTANCE_ID" \
      --query 'Status' --output text 2>/dev/null) || STATUS="Failed"
  done

  # Get output as JSON to preserve newlines
  local RAW
  RAW=$(aws ssm get-command-invocation \
    --command-id "$CMD_ID" \
    --instance-id "$INSTANCE_ID" \
    --output json 2>/dev/null)

  python3 -c "import json,sys; d=json.loads(sys.stdin.read()); print(d.get('StandardOutputContent',''))" <<< "$RAW"

  local STDERR
  STDERR=$(python3 -c "import json,sys; d=json.loads(sys.stdin.read()); s=d.get('StandardErrorContent',''); print(s) if s.strip() else None" <<< "$RAW" 2>/dev/null || true)
  if [[ -n "$STDERR" ]]; then
    echo "[STDERR] $STDERR" >&2
  fi

  if [[ "$STATUS" != "Success" ]]; then
    echo "[SSM command status: $STATUS]" >&2
    return 1
  fi
}

upload_and_run() {
  # Upload a local script to the Mac via SSM (base64 encode), then execute it
  local LOCAL_SCRIPT="$1"
  local TIMEOUT="${2:-600}"

  local B64
  B64=$(base64 < "$LOCAL_SCRIPT" | tr -d '\n')

  # Commands: decode script, make executable, run it
  local COMMANDS_JSON
  COMMANDS_JSON=$(python3 -c "
import json, sys
b64 = sys.argv[1]
cmds = [
    'echo ' + b64 + ' | base64 -d > /tmp/openclaw-mac-test.sh',
    'chmod +x /tmp/openclaw-mac-test.sh',
    'bash /tmp/openclaw-mac-test.sh',
    'rm -f /tmp/openclaw-mac-test.sh'
]
print(json.dumps(cmds))
" "$B64")

  ssm_exec "$COMMANDS_JSON" "$TIMEOUT"
}

case "${1:-help}" in
  info)
    echo "=== Mac Instance Details ==="
    echo "Instance: $INSTANCE_ID ($INSTANCE_NAME)"
    echo "Access: SSM Session Manager"
    echo ""
    echo "=== Remote Environment ==="
    ssm_exec '["export PATH=/opt/homebrew/bin:/usr/local/bin:$PATH","sw_vers","echo Arch: $(uname -m)","echo Bash: $BASH_VERSION","echo User: $(whoami)","node --version 2>/dev/null || echo Node.js: not installed","git --version 2>/dev/null || echo git: not installed"]' 30
    ;;

  test)
    echo "=== Running macOS E2E test via SSM ==="
    echo ""
    upload_and_run "$REMOTE_SCRIPT" 600
    ;;

  report)
    mkdir -p "$REPORT_DIR"
    REPORT_FILE="$REPORT_DIR/macos-e2e-$(date +%Y%m%d-%H%M%S).log"
    echo "=== Running macOS E2E test via SSM ==="
    echo "Report: $REPORT_FILE"
    echo ""
    upload_and_run "$REMOTE_SCRIPT" 600 2>&1 | tee "$REPORT_FILE"
    echo ""
    echo "Report saved: $REPORT_FILE"
    ;;

  help|*)
    echo "Usage: bash scripts/aws/mac-test.sh {info|test|report}"
    echo ""
    echo "Commands:"
    echo "  info    Show instance details and environment"
    echo "  test    Run full E2E test suite on macOS via SSM"
    echo "  report  Run tests and save report to reports/"
    ;;
esac
