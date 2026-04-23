#!/usr/bin/env bash
# Test T008: Verify setup script exists and has required functions
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

SCRIPT="scripts/openclaw-setup.sh"
[ -f "$SCRIPT" ] || { echo "FAIL: $SCRIPT missing"; exit 1; }

PASS=0; FAIL=0
check() { if grep -q "$1" "$SCRIPT"; then echo "PASS: has '$1'"; ((PASS++)); else echo "FAIL: missing '$1'"; ((FAIL++)); fi; }

check "check_prereqs"
check "install_openclaw"
check "interview_user"
check "store_secrets"
check "configure_openclaw"
check "start_and_verify"
check "openclaw config set"
check "chmod 600"
check "dry-run"

# Verify valid bash syntax
bash -n "$SCRIPT" && { echo "PASS: valid bash syntax"; ((PASS++)); } || { echo "FAIL: syntax error"; ((FAIL++)); }

echo "---"
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
