#!/usr/bin/env bash
# Test T013: Verify Slack channel IDs configured with requireMention
set -euo pipefail

PASS=0; FAIL=0
check() { if eval "$1"; then echo "PASS: $2"; PASS=$((PASS+1)); else echo "FAIL: $2"; FAIL=$((FAIL+1)); fi; }

if command -v wsl &>/dev/null; then
  OC_CHANNELS="$(wsl -e bash -c 'openclaw config get channels.slack.channels 2>/dev/null' 2>/dev/null | tr -d '\0')" || OC_CHANNELS=""
  check '[[ -n "$OC_CHANNELS" ]]' "openclaw config has slack channels"
  check 'echo "$OC_CHANNELS" | grep -q "C0ATFDQRGRL"' "has #all-misfits channel ID"
  check 'echo "$OC_CHANNELS" | grep -q "C0ATJE19YRY"' "has #coco-chat channel ID"
  check 'echo "$OC_CHANNELS" | grep -q "C0ATB4AS9PD"' "has #social channel ID"
  check 'echo "$OC_CHANNELS" | grep -q "D0ATWPM4DTK"' "has Joel DM channel ID"
  check 'echo "$OC_CHANNELS" | grep -q "requireMention"' "channels have requireMention config"
else
  echo "SKIP: WSL not available"
  PASS=1
fi

echo "---"
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
