#!/usr/bin/env bash
# Test T012: Verify skill packaging is ready for marketplace publish
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

PASS=0; FAIL=0
check() { if eval "$1"; then echo "PASS: $2"; PASS=$((PASS+1)); else echo "FAIL: $2"; FAIL=$((FAIL+1)); fi; }

check '[ -f "skill/SKILL.md" ]' "skill/SKILL.md exists"
check 'grep -q "openclaw" "skill/SKILL.md"' "SKILL.md mentions openclaw"
check 'grep -q "TRIGGER" "skill/SKILL.md" || grep -qi "trigger" "skill/SKILL.md"' "SKILL.md has trigger keywords"
check '[ -f ".github/publish.json" ]' ".github/publish.json exists"
check 'grep -q "grobomo" ".github/publish.json"' "publish.json targets grobomo account"

echo "---"
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
