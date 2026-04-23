#!/usr/bin/env bash
# Test T014: Signal channel config (deferred - no Signal account configured)
# Validates the setup script has signal support
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

PASS=0; FAIL=0
check() { if eval "$1"; then echo "PASS: $2"; PASS=$((PASS+1)); else echo "FAIL: $2"; FAIL=$((FAIL+1)); fi; }

SCRIPT="scripts/openclaw-setup.sh"
check 'grep -q "signal" "$SCRIPT"' "setup script has signal channel support"
check 'grep -q "channels.signal.enabled" "$SCRIPT"' "setup script configures signal enabled"
check 'grep -q "signal-cli" "$SCRIPT"' "setup script references signal-cli"

echo "---"
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
