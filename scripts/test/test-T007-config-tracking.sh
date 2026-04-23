#!/usr/bin/env bash
# Test T007: Verify config tracking is documented
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

FILE="docs/setup-log.md"
[ -f "$FILE" ] || { echo "FAIL: $FILE missing"; exit 1; }

PASS=0; FAIL=0
check() { if grep -qi "$1" "$FILE"; then echo "PASS: has '$1'"; PASS=$((PASS+1)); else echo "FAIL: missing '$1'"; FAIL=$((FAIL+1)); fi; }

check "Config Change Tracking"
check "git"
check "openclaw config"

echo "---"
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
