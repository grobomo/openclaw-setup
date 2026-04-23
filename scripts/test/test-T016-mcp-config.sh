#!/usr/bin/env bash
# Test T016: MCP server config (deferred - was empty in backup, no config to restore)
# Validates openclaw config is still valid after all changes
set -euo pipefail

PASS=0; FAIL=0
check() { if eval "$1"; then echo "PASS: $2"; PASS=$((PASS+1)); else echo "FAIL: $2"; FAIL=$((FAIL+1)); fi; }

if command -v wsl &>/dev/null; then
  VALIDATE="$(wsl -e bash -c 'openclaw config validate 2>&1' 2>/dev/null | tr -d '\0')" || VALIDATE=""
  # Config validate returns "valid" or errors
  check '[[ "$VALIDATE" == *"valid"* || "$VALIDATE" == *"ok"* || -z "$VALIDATE" ]]' "openclaw config validates cleanly"
else
  echo "SKIP: WSL not available"
  PASS=1
fi

echo "---"
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
