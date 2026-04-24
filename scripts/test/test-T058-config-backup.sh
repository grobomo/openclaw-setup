#!/usr/bin/env bash
# Test T058-T060: Config backup/restore/diff scripts
PASS=0; FAIL=0
check() {
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "PASS: $desc"; ((PASS++))
  else
    echo "FAIL: $desc"; ((FAIL++))
  fi
}

SCRIPT="scripts/config-backup.sh"

# Script exists and has valid syntax
check "config-backup.sh exists" test -f "$SCRIPT"
check "valid bash syntax" bash -n "$SCRIPT"

# Has all four commands
check "has backup command" grep -q 'do_backup()' "$SCRIPT"
check "has restore command" grep -q 'do_restore()' "$SCRIPT"
check "has diff command" grep -q 'do_diff()' "$SCRIPT"
check "has list command" grep -q 'do_list()' "$SCRIPT"

# Safety: validates JSON before backup
check "validates JSON before backup" grep -q 'JSON.parse.*readFileSync' "$SCRIPT"

# Safety: backs up current config before restore
check "pre-restore backup" grep -q 'pre-restore' "$SCRIPT"

# Safety: validates after restore
check "post-restore validation" grep -q 'Restored config is invalid' "$SCRIPT"

# Uses metadata wrapper
check "backup has metadata wrapper" grep -q '_backup' "$SCRIPT"
check "metadata includes sha256" grep -q 'sha256' "$SCRIPT"

# No dangerous patterns
check "no eval" bash -c '! grep -q "eval " '"$SCRIPT"

echo "---"
echo "Results: $PASS passed, $FAIL failed"
exit $FAIL
