#!/usr/bin/env bash
# Test T028: Integration readiness — project structure, docs, marketplace presence
set -euo pipefail
PASS=0; FAIL=0
check() {
  if eval "$2"; then
    echo "PASS: $1"; ((PASS++))
  else
    echo "FAIL: $1"; ((FAIL++))
  fi
}

# Marketplace plugin exists
check "SKILL.md exists" "[[ -f skill/SKILL.md ]]"
check "README.md exists" "[[ -f README.md ]]"
check "explainer HTML exists" "[[ -f docs/openclaw-setup-explainer.html ]]"

# Git remote is grobomo
check "remote is grobomo" "git remote -v | grep -q 'grobomo/openclaw-setup'"

# publish.json correct
check "publish.json says grobomo" "grep -q 'grobomo' .github/publish.json"

# CI workflow exists
check "secret-scan workflow exists" "[[ -f .github/workflows/secret-scan.yml ]]"

# No secrets in repo
check "no API keys in tracked files" "! git grep -iE '(xoxb-|xapp-|sk-[a-zA-Z0-9]{20,}|AKIA[A-Z0-9]{16})' -- ':!scripts/test/' ':!.github/workflows/'"

echo "---"
echo "Results: $PASS passed, $FAIL failed"
exit $FAIL
