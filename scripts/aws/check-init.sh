#!/usr/bin/env bash
# Check cloud-init log on EC2 instance
set -euo pipefail

KEY_FILE="$HOME/.ssh/openclaw-e2e-key.pem"
STACK_NAME="openclaw-e2e-test"

IP=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" \
  --query 'Stacks[0].Outputs[?OutputKey==`PublicIP`].OutputValue' --output text 2>/dev/null)

ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -i "$KEY_FILE" ubuntu@"$IP" \
  'cat /var/log/openclaw-e2e-init.log 2>/dev/null || echo "No init log"; echo "---"; cloud-init status --long 2>/dev/null'
