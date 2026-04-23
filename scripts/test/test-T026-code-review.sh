#!/usr/bin/env bash
# Test T026: Code review fixes — verify security and quality improvements
PASS=0; FAIL=0
check() {
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "PASS: $desc"; ((PASS++))
  else
    echo "FAIL: $desc"; ((FAIL++))
  fi
}
check_not() {
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "FAIL: $desc"; ((FAIL++))
  else
    echo "PASS: $desc"; ((PASS++))
  fi
}

SCRIPT="scripts/openclaw-setup.sh"

# Security: no eval with user input
check_not "no eval in log_cmd" grep -q 'eval "$cmd"' "$SCRIPT"

# log_cmd uses direct execution via "$@"
check "log_cmd uses direct exec" grep -qF '"$@"' "$SCRIPT"

# Provider 2 (OpenAI) handled
check "OpenAI provider case exists" grep -q 'PROVIDER_NAME="openai"' "$SCRIPT"

# Provider 3 (OpenRouter) handled
check "OpenRouter provider case exists" grep -q 'PROVIDER_NAME="openrouter"' "$SCRIPT"

# Redact sensitive should NOT be off
check_not "redactSensitive not set to off" grep -q 'redactSensitive off' "$SCRIPT"

# docs/ directory created before logging
check "mkdir for docs/ before log" grep -q 'mkdir -p.*docs' "$SCRIPT"

# env_set helper for dedup
check "env_set dedup helper exists" grep -q 'env_set()' "$SCRIPT"

# Channel tokens use env_set (dedup)
check "slack tokens use env_set" grep -q 'env_set "SLACK_BOT_TOKEN"' "$SCRIPT"

# OC_CONTEXT_WINDOW documented in header
check "OC_CONTEXT_WINDOW documented in header" bash -c 'head -35 '"$SCRIPT"' | grep -q OC_CONTEXT_WINDOW'

# Bash 3.2 compat: CHANNEL_LIST uses ${arr[@]+...} pattern for empty arrays
check "bash 3.2 safe array expansion" grep -q 'CHANNEL_LIST\[@\]+"' "$SCRIPT"

# Bash 3.2 compat: no ${VAR^^} uppercase (Bash 4+ only), use tr instead
check_not "no bash4 uppercase syntax" grep -q '^^}' "$SCRIPT"

# Valid bash syntax
check "valid bash syntax" bash -n "$SCRIPT"

echo "---"
echo "Results: $PASS passed, $FAIL failed"
exit $FAIL
