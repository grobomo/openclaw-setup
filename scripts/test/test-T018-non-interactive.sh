#!/usr/bin/env bash
# Test T018: Verify setup script supports --non-interactive mode
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

SCRIPT="scripts/openclaw-setup.sh"
[ -f "$SCRIPT" ] || { echo "FAIL: $SCRIPT missing"; exit 1; }

PASS=0; FAIL=0
check() { if eval "$1"; then echo "PASS: $2"; PASS=$((PASS+1)); else echo "FAIL: $2"; FAIL=$((FAIL+1)); fi; }

# T018: Script must accept --non-interactive flag
check 'grep -q "\-\-non-interactive" "$SCRIPT"' "accepts --non-interactive flag"
check 'grep -q "NON_INTERACTIVE" "$SCRIPT"' "has NON_INTERACTIVE variable"

# In non-interactive mode, should skip read prompts and use defaults/env vars
check 'grep -q "NON_INTERACTIVE.*true" "$SCRIPT"' "checks NON_INTERACTIVE flag to skip prompts"

# Should document required env vars for non-interactive mode
check 'grep -q "OC_PROVIDER" "$SCRIPT"' "has env var for provider selection"
check 'grep -q "OC_CHANNELS" "$SCRIPT"' "has env var for channel selection"

# Verify valid bash syntax
bash -n "$SCRIPT" && { echo "PASS: valid bash syntax"; PASS=$((PASS+1)); } || { echo "FAIL: syntax error"; FAIL=$((FAIL+1)); }

echo "---"
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
