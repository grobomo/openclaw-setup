#!/usr/bin/env bash
# Test T001: Verify project scaffolding exists
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

PASS=0; FAIL=0
check() { if [ -e "$1" ]; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1 missing"; ((FAIL++)); fi; }

check ".github/publish.json"
check ".github/workflows/secret-scan.yml"
check "docs/research.md"
check "scripts/test/test-T001-project-scaffolding.sh"
check "TODO.md"

echo "---"
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
