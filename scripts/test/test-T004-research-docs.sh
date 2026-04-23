#!/usr/bin/env bash
# Test T004: Verify research doc has required sections
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

FILE="docs/research.md"
[ -f "$FILE" ] || { echo "FAIL: $FILE missing"; exit 1; }

PASS=0; FAIL=0
check() { if grep -q "$1" "$FILE"; then echo "PASS: has '$1'"; PASS=$((PASS+1)); else echo "FAIL: missing '$1'"; FAIL=$((FAIL+1)); fi; }

check "Sources"
check "Architecture"
check "Installation"
check "Configuration"
check "Known Issues"
check "Security"
check "Recovery"
check "CLI Quick Reference"

echo "---"
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
