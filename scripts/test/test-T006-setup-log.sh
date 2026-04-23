#!/usr/bin/env bash
# Test T006: Verify setup log has detailed entries and root cause analysis
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

FILE="docs/setup-log.md"
[ -f "$FILE" ] || { echo "FAIL: $FILE missing"; exit 1; }

PASS=0; FAIL=0
check() { if grep -qi "$1" "$FILE"; then echo "PASS: has '$1'"; ((PASS++)); else echo "FAIL: missing '$1'"; ((FAIL++)); fi; }

check "2026-04"
check "Root Cause"
check "Recovery Steps"
check "openclaw config set"
check "Environment Files"

echo "---"
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
