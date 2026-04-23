#!/usr/bin/env bash
# Test T017: Verify setup script uses atomic model definitions (--json)
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

SCRIPT="scripts/openclaw-setup.sh"
[ -f "$SCRIPT" ] || { echo "FAIL: $SCRIPT missing"; exit 1; }

PASS=0; FAIL=0
check() { if eval "$1"; then echo "PASS: $2"; PASS=$((PASS+1)); else echo "FAIL: $2"; FAIL=$((FAIL+1)); fi; }

# T017: Custom endpoint (case 4) must use --json for atomic provider definition
check 'grep -q "\-\-json" "$SCRIPT"' "setup script uses --json flag for atomic config"
check 'grep -q "models.providers" "$SCRIPT"' "setup script configures model providers"
check 'grep -q "contextWindow" "$SCRIPT"' "setup script includes model contextWindow in definition"
check 'grep -q "maxTokens" "$SCRIPT"' "setup script includes model maxTokens in definition"

# Verify the script doesn't set provider fields one-by-one (the old broken way)
check '! grep -q "models\.providers\.\${PROVIDER_NAME}\.baseUrl" "$SCRIPT"' "no separate baseUrl set (uses atomic --json instead)"
check '! grep -q "models\.providers\.\${PROVIDER_NAME}\.api " "$SCRIPT"' "no separate api set (uses atomic --json instead)"

# Verify valid bash syntax
bash -n "$SCRIPT" && { echo "PASS: valid bash syntax"; PASS=$((PASS+1)); } || { echo "FAIL: syntax error"; FAIL=$((FAIL+1)); }

echo "---"
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
