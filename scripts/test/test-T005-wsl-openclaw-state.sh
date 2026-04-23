#!/usr/bin/env bash
# Test T005: Verify OpenClaw state is documented in setup log
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

FILE="docs/setup-log.md"
[ -f "$FILE" ] || { echo "FAIL: $FILE missing"; exit 1; }

PASS=0; FAIL=0
check() { if grep -qi "$1" "$FILE"; then echo "PASS: has '$1'"; ((PASS++)); else echo "FAIL: missing '$1'"; ((FAIL++)); fi; }

check "openclaw"
check "gateway"
check "config"
check "2026"

echo "---"
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
