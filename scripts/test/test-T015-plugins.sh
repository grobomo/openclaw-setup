#!/usr/bin/env bash
# Test T015: Verify plugins are enabled in OpenClaw config
set -euo pipefail

PASS=0; FAIL=0
check() { if eval "$1"; then echo "PASS: $2"; PASS=$((PASS+1)); else echo "FAIL: $2"; FAIL=$((FAIL+1)); fi; }

if command -v wsl &>/dev/null; then
  PLUGINS="$(wsl -e bash -c 'openclaw config get plugins.entries 2>/dev/null' 2>/dev/null | tr -d '\0')" || PLUGINS=""
  check '[[ -n "$PLUGINS" ]]' "openclaw plugins config readable"
  check 'echo "$PLUGINS" | grep -q "coconut-guardrails"' "coconut-guardrails plugin present"
  check 'echo "$PLUGINS" | grep -q "hook-runner-gates"' "hook-runner-gates plugin present"
  check 'echo "$PLUGINS" | grep -q "memory-core"' "memory-core plugin present"
  check 'echo "$PLUGINS" | grep -q "slack"' "slack plugin present"
else
  echo "SKIP: WSL not available"
  PASS=1
fi

echo "---"
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
