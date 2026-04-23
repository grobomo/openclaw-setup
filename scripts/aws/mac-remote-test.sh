#!/bin/bash
# mac-remote-test.sh — Runs ON the Mac instance (uploaded via SSM)
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
export HOME="${HOME:-/var/root}"
set -uo pipefail

echo "==========================================="
echo "  macOS E2E Test — openclaw-setup"
echo "==========================================="
echo ""

echo "=== Environment ==="
echo "OS: $(sw_vers -productName) $(sw_vers -productVersion)"
echo "Arch: $(uname -m)"
echo "Bash: $BASH_VERSION"
echo "User: $(whoami)"
echo "HOME: $HOME"
echo ""

echo "=== Node.js ==="
if command -v node >/dev/null 2>&1; then
  echo "node $(node --version)"
  echo "npm $(npm --version)"
else
  echo "Node.js not found. Installing from nodejs.org binary..."
  ARCH=$(uname -m)
  if [ "$ARCH" = "arm64" ]; then
    NODE_ARCH="arm64"
  else
    NODE_ARCH="x64"
  fi
  NODE_VER="v22.16.0"
  curl -fsSL "https://nodejs.org/dist/${NODE_VER}/node-${NODE_VER}-darwin-${NODE_ARCH}.tar.gz" -o /tmp/node.tar.gz
  tar xzf /tmp/node.tar.gz -C /usr/local --strip-components=1
  rm /tmp/node.tar.gz
  echo "node $(node --version)"
  echo "npm $(npm --version)"
fi
echo ""

echo "=== Clone/update repo ==="
WORK_DIR="/tmp/openclaw-setup-test"
BRANCH="${OC_TEST_BRANCH:-main}"
rm -rf "$WORK_DIR"
git clone --branch "$BRANCH" --single-branch https://github.com/grobomo/openclaw-setup.git "$WORK_DIR"
cd "$WORK_DIR"
echo "HEAD: $(git log --oneline -1)"
echo ""

echo "=== Dry-run: Anthropic ==="
OC_PROVIDER=1 bash scripts/openclaw-setup.sh --dry-run --non-interactive --skip-install 2>&1
echo ""

echo "=== Dry-run: OpenAI ==="
OC_PROVIDER=2 bash scripts/openclaw-setup.sh --dry-run --non-interactive --skip-install 2>&1
echo ""

echo "=== Dry-run: OpenRouter ==="
OC_PROVIDER=3 bash scripts/openclaw-setup.sh --dry-run --non-interactive --skip-install 2>&1
echo ""

echo "=== Dry-run: Custom provider ==="
OC_PROVIDER=4 OC_PROVIDER_NAME=testprov OC_BASE_URL=https://api.test.com/v1 \
  OC_MODEL_ID=test-model OC_CHANNELS=slack,telegram \
  bash scripts/openclaw-setup.sh --dry-run --non-interactive --skip-install 2>&1
echo ""

echo "=== Dry-run: Ollama ==="
OC_PROVIDER=5 bash scripts/openclaw-setup.sh --dry-run --non-interactive --skip-install 2>&1
echo ""

echo "=== Test suites ==="
TOTAL_PASS=0
TOTAL_FAIL=0
SUITE_RESULTS=""
for t in scripts/test/test-*.sh; do
  name=$(basename "$t")
  output=$(bash "$t" 2>&1) || true
  p=$(echo "$output" | grep -c "^PASS:" || true)
  f=$(echo "$output" | grep -c "^FAIL:" || true)
  TOTAL_PASS=$((TOTAL_PASS + p))
  TOTAL_FAIL=$((TOTAL_FAIL + f))
  if [ "$f" -gt 0 ]; then
    SUITE_RESULTS="${SUITE_RESULTS}FAIL  ${name} (${p} pass, ${f} fail)
"
    echo "--- FAILURES in $name ---"
    echo "$output" | grep "^FAIL:"
  else
    SUITE_RESULTS="${SUITE_RESULTS}PASS  ${name} (${p} pass)
"
  fi
done
echo ""

echo "==========================================="
echo "  SUITE DETAILS"
echo "==========================================="
echo "$SUITE_RESULTS"
echo ""
echo "==========================================="
echo "  macOS E2E RESULTS: $TOTAL_PASS passed, $TOTAL_FAIL failed"
echo "  Bash version: $BASH_VERSION"
echo "  macOS: $(sw_vers -productVersion)"
echo "==========================================="

rm -rf "$WORK_DIR"
