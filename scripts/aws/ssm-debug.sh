#!/usr/bin/env bash
set -euo pipefail
INSTANCE_ID="i-03b1aa541596068c9"

CMD_ID=$(aws ssm send-command \
  --instance-ids "$INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --parameters '{"commands":["export PATH=/opt/homebrew/bin:/usr/local/bin:$PATH; echo OS: $(sw_vers -productName) $(sw_vers -productVersion); echo Arch: $(uname -m); echo Bash: $BASH_VERSION; echo User: $(whoami); which node 2>/dev/null || echo node-missing; which brew 2>/dev/null || echo brew-missing; which git 2>/dev/null || echo git-missing; git --version 2>/dev/null || true"]}' \
  --timeout-seconds 30 \
  --query 'Command.CommandId' --output text)

sleep 8

aws ssm get-command-invocation \
  --command-id "$CMD_ID" \
  --instance-id "$INSTANCE_ID" \
  --query 'StandardOutputContent' --output json 2>/dev/null
