#!/usr/bin/env bash
# ec2-test.sh — Launch/manage a spot instance for E2E testing openclaw-setup
# Usage:
#   bash scripts/aws/ec2-test.sh launch    # Create keypair + stack
#   bash scripts/aws/ec2-test.sh status    # Check instance status
#   bash scripts/aws/ec2-test.sh ssh       # SSH into the instance
#   bash scripts/aws/ec2-test.sh test      # Run the E2E test remotely
#   bash scripts/aws/ec2-test.sh teardown  # Delete stack + keypair

set -euo pipefail

STACK_NAME="openclaw-e2e-test"
KEY_NAME="openclaw-e2e-key"
KEY_FILE="$HOME/.ssh/${KEY_NAME}.pem"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE="$SCRIPT_DIR/ec2-spot-template.yaml"
AWS_SKILL="$HOME/.claude/skills/aws/aws.sh"

get_output() {
  aws cloudformation describe-stacks --stack-name "$STACK_NAME" \
    --query "Stacks[0].Outputs[?OutputKey==\`$1\`].OutputValue" --output text 2>/dev/null
}

get_ssh_args() {
  local IP
  IP=$(get_output PublicIP)
  if [[ -z "$IP" || "$IP" == "None" ]]; then
    echo "ERROR: No IP found. Is the stack running?" >&2
    exit 1
  fi
  if [[ ! -f "$KEY_FILE" || ! -s "$KEY_FILE" ]]; then
    echo "ERROR: SSH key not found at $KEY_FILE" >&2
    exit 1
  fi
  echo "-o StrictHostKeyChecking=no -o ConnectTimeout=10 -i $KEY_FILE ubuntu@$IP"
}

case "${1:-help}" in
  launch)
    echo "=== Creating SSH keypair ==="
    if aws ec2 describe-key-pairs --key-names "$KEY_NAME" >/dev/null 2>&1; then
      echo "Keypair $KEY_NAME already exists in AWS"
    else
      aws ec2 create-key-pair --key-name "$KEY_NAME" \
        --query 'KeyMaterial' --output text > "$KEY_FILE"
      chmod 600 "$KEY_FILE"
      echo "Created keypair: $KEY_NAME -> $KEY_FILE"
    fi

    echo ""
    echo "=== Launching EC2 spot instance ==="
    "$AWS_SKILL" cf deploy "$STACK_NAME" "$TEMPLATE"
    echo "Waiting for stack to complete..."
    aws cloudformation wait stack-create-complete --stack-name "$STACK_NAME" 2>/dev/null || true
    "$AWS_SKILL" cf outputs "$STACK_NAME"
    echo ""
    echo "Instance is booting. Wait ~60s for cloud-init, then run: bash scripts/aws/ec2-test.sh test"
    ;;

  status)
    "$AWS_SKILL" cf status "$STACK_NAME"
    "$AWS_SKILL" cf outputs "$STACK_NAME" 2>/dev/null || echo "No outputs yet"
    ;;

  ssh)
    SSH_ARGS=$(get_ssh_args)
    echo "Connecting..."
    ssh $SSH_ARGS
    ;;

  test)
    SSH_ARGS=$(get_ssh_args)
    echo "=== Running E2E test on EC2 ==="
    ssh $SSH_ARGS 'bash -s' <<'REMOTE_SCRIPT'
set -euo pipefail
echo "=== Environment ==="
uname -a
echo ""

# Wait for cloud-init to finish
echo "Waiting for cloud-init..."
cloud-init status --wait 2>/dev/null || sleep 30
echo ""

echo "=== Node.js ==="
node --version
npm --version
echo ""

echo "=== Clone repo ==="
if [[ ! -d "$HOME/openclaw-setup" ]]; then
  git clone https://github.com/grobomo/openclaw-setup.git "$HOME/openclaw-setup"
else
  cd "$HOME/openclaw-setup" && git pull
fi
cd "$HOME/openclaw-setup"
echo ""

echo "=== Dry-run test (Anthropic, non-interactive) ==="
OC_PROVIDER=1 bash scripts/openclaw-setup.sh --dry-run --non-interactive --skip-install
echo ""

echo "=== Dry-run with custom provider ==="
OC_PROVIDER=4 OC_PROVIDER_NAME=testprov OC_BASE_URL=https://api.test.com/v1 \
  OC_MODEL_ID=test-model OC_CHANNELS=slack,telegram \
  bash scripts/openclaw-setup.sh --dry-run --non-interactive --skip-install
echo ""

echo "=== Dry-run with OpenAI ==="
OC_PROVIDER=2 bash scripts/openclaw-setup.sh --dry-run --non-interactive --skip-install
echo ""

echo "=== Dry-run with OpenRouter ==="
OC_PROVIDER=3 bash scripts/openclaw-setup.sh --dry-run --non-interactive --skip-install
echo ""

echo "=== Dry-run with Ollama ==="
OC_PROVIDER=5 bash scripts/openclaw-setup.sh --dry-run --non-interactive --skip-install
echo ""

echo "=== Test suites ==="
TOTAL_PASS=0 TOTAL_FAIL=0
for t in scripts/test/test-*.sh; do
  output=$(bash "$t" 2>&1) || true
  p=$(echo "$output" | grep -c "^PASS:" || true)
  f=$(echo "$output" | grep -c "^FAIL:" || true)
  TOTAL_PASS=$((TOTAL_PASS + p))
  TOTAL_FAIL=$((TOTAL_FAIL + f))
  if [[ $f -gt 0 ]]; then
    echo "=== FAILURES in $(basename "$t") ==="
    echo "$output" | grep "^FAIL:"
  fi
done
echo ""
echo "=========================================="
echo "  EC2 E2E RESULTS: $TOTAL_PASS passed, $TOTAL_FAIL failed"
echo "=========================================="
REMOTE_SCRIPT
    ;;

  teardown)
    echo "=== Deleting stack $STACK_NAME ==="
    "$AWS_SKILL" cf delete "$STACK_NAME"
    echo "Waiting for stack deletion..."
    aws cloudformation wait stack-delete-complete --stack-name "$STACK_NAME" 2>/dev/null || true
    echo ""
    echo "=== Deleting keypair ==="
    aws ec2 delete-key-pair --key-name "$KEY_NAME" 2>/dev/null || true
    rm -f "$KEY_FILE"
    echo "Cleaned up keypair: $KEY_NAME"
    ;;

  help|*)
    echo "Usage: bash scripts/aws/ec2-test.sh {launch|status|ssh|test|teardown}"
    ;;
esac
