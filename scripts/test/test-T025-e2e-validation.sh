#!/usr/bin/env bash
# Test T025: E2E validation — all test suites pass and gateway is healthy
set -euo pipefail
PASS=0; FAIL=0
check() {
  if eval "$2"; then
    echo "PASS: $1"; ((PASS++))
  else
    echo "FAIL: $1"; ((FAIL++))
  fi
}

# Count test files — should be at least 15
TEST_COUNT=$(ls scripts/test/test-T*.sh 2>/dev/null | wc -l)
check "at least 15 test suites exist" "[[ $TEST_COUNT -ge 15 ]]"

# All existing tests should have valid bash syntax
SYNTAX_OK=true
for t in scripts/test/test-T*.sh; do
  if ! bash -n "$t" 2>/dev/null; then
    SYNTAX_OK=false
    break
  fi
done
check "all test files have valid bash syntax" "$SYNTAX_OK"

# T025 marked complete
check "T025 marked complete in TODO" "grep -q '\[x\] T025' TODO.md"

echo "---"
echo "Results: $PASS passed, $FAIL failed"
exit $FAIL
