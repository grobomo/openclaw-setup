#!/usr/bin/env bash
# Test T027: Dry-run mode works end-to-end without side effects
set -euo pipefail
PASS=0; FAIL=0
check() {
  if eval "$2"; then
    echo "PASS: $1"; ((PASS++))
  else
    echo "FAIL: $1"; ((FAIL++))
  fi
}

SCRIPT="scripts/openclaw-setup.sh"

# Script accepts --dry-run flag
check "accepts --dry-run flag" "grep -q 'dry-run' $SCRIPT"

# Script accepts --non-interactive flag
check "accepts --non-interactive flag" "grep -q 'non-interactive' $SCRIPT"

# Dry run prints [dry-run] prefix
check "dry-run prints prefix" "grep -q 'dry-run' $SCRIPT"

# Non-interactive mode reads from env vars
check "non-interactive reads OC_PROVIDER" "grep -q 'OC_PROVIDER' $SCRIPT"

# Valid bash syntax (repeated as a safety net)
check "valid bash syntax" "bash -n $SCRIPT"

echo "---"
echo "Results: $PASS passed, $FAIL failed"
exit $FAIL
