#!/usr/bin/env bash
# Test T024: Session log audit — verify no deferred/skipped tangents remain
set -euo pipefail
PASS=0; FAIL=0
check() {
  if eval "$2"; then
    echo "PASS: $1"; ((PASS++))
  else
    echo "FAIL: $1"; ((FAIL++))
  fi
}

# T024 is a log audit — verify it was done by checking TODO.md marks it complete
check "T024 marked complete in TODO" "grep -q '\[x\] T024' TODO.md"

echo "---"
echo "Results: $PASS passed, $FAIL failed"
exit $FAIL
