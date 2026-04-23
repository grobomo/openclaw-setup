#!/usr/bin/env bash
# Probe Mac instance for SSH access with available keys
set -uo pipefail
IP="18.218.210.27"

echo "=== Checking SSM availability ==="
aws ssm describe-instance-information --filters "Key=InstanceIds,Values=i-03b1aa541596068c9" \
  --query 'InstanceInformationList[0].PingStatus' --output text 2>/dev/null || echo "SSM not available"

echo ""
echo "=== Trying SSH keys ==="
for key in \
  "$HOME/.ssh/dd-lab-jumpbox" \
  "$HOME/.ssh/cpp-keys/jumpbox.pem" \
  "$HOME/.ssh/cpp-keys/test2.pem" \
  "$HOME/.ssh/cpp-keys/test3.pem" \
  "$HOME/.ssh/ccc-keys/ccc-test.pem" \
  "$HOME/.ssh/claude-portable-ec2.pem"; do
  if [[ -f "$key" && -s "$key" ]]; then
    for user in ec2-user admin ubuntu; do
      result=$(ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -o BatchMode=yes \
        -i "$key" "${user}@${IP}" 'echo OK' 2>&1) || true
      if [[ "$result" == "OK" ]]; then
        echo "SUCCESS: $key as $user"
        exit 0
      fi
    done
    echo "FAIL: $(basename "$key")"
  fi
done
echo "No working key found."
