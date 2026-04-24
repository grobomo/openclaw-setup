#!/usr/bin/env bash
# Test T083: README assertion count matches actual test output
PASS=0; FAIL=0
check() {
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "PASS: $desc"; ((PASS++))
  else
    echo "FAIL: $desc"; ((FAIL++))
  fi
}

# Count actual assertions across all test suites
ACTUAL=0
for t in scripts/test/test-*.sh; do
  p=$(bash "$t" 2>&1 | grep -c "^PASS:")
  ACTUAL=$((ACTUAL + p))
done

# Check README mentions the correct count
check "README assertion count matches actual ($ACTUAL)" grep -q "$ACTUAL assertions" README.md

echo "---"
echo "Results: $PASS passed, $FAIL failed"
exit $FAIL
