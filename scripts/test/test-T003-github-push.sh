#!/usr/bin/env bash
# Test T003: Verify git repo is properly configured
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

PASS=0; FAIL=0
check() { if eval "$1" &>/dev/null; then echo "PASS: $2"; ((PASS++)); else echo "FAIL: $2"; ((FAIL++)); fi; }

check 'git rev-parse --is-inside-work-tree' 'is a git repo'
check 'git config user.name' 'user.name set'
check 'git config user.email' 'user.email set'
check 'git remote get-url origin' 'remote origin set'

echo "---"
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
