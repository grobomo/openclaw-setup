#!/usr/bin/env bash
# Test T002: Verify secret-scan workflow has required patterns
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

FILE=".github/workflows/secret-scan.yml"
[ -f "$FILE" ] || { echo "FAIL: $FILE missing"; exit 1; }

PASS=0; FAIL=0
check() { if grep -q "$1" "$FILE"; then echo "PASS: scans for $2"; PASS=$((PASS+1)); else echo "FAIL: missing $2"; FAIL=$((FAIL+1)); fi; }

check 'subscription' 'subscription IDs'
check 'API key' 'API keys'
check 'password' 'passwords'
check 'on:' 'workflow trigger'

echo "---"
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
