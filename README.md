# openclaw-setup

Repeatable OpenClaw deployment with guided setup, secure secret management, and automation for CI/fleet use.

## The Problem

OpenClaw's JSON config is fragile. Agents editing `openclaw.json` directly corrupt JSON syntax (Bug #6028), the gateway silently overwrites config on startup (#11355), and secrets pasted into config files end up in git history. Every manual setup is a new opportunity to break something.

## How It Works

```
1. Prerequisites check (Node.js 22.16+, platform detection)
2. Interactive interview OR non-interactive env vars (OC_* variables)
3. Model provider config via `openclaw config set` (never direct JSON edits)
4. Secrets stored in ~/.openclaw/.env (chmod 600)
5. Gateway start + doctor verification
6. All commands logged with timestamps
```

The setup script uses `openclaw config set` exclusively -- no direct JSON editing. Custom providers are set atomically with `--json` to prevent validation errors from partial schema states.

## Install

```bash
git clone https://github.com/grobomo/openclaw-setup.git
cd openclaw-setup
bash scripts/openclaw-setup.sh
```

## Configuration

| File | Purpose |
|------|---------|
| `scripts/openclaw-setup.sh` | Main setup script -- interview, configure, verify |
| `skill/SKILL.md` | Claude Code skill definition for marketplace |
| `docs/research.md` | Consolidated research from 7 sources (official docs, bugs, guides) |
| `docs/setup-log.md` | Timestamped log of every setup command with root cause analysis |
| `scripts/test/test-T*.sh` | 20 test suites (94 assertions) covering all tasks |
| `scripts/aws/ec2-test.sh` | EC2 spot instance launcher for E2E testing on clean Linux |
| `scripts/aws/ec2-spot-template.yaml` | CloudFormation template (t3.micro, Ubuntu 24.04) |
| `scripts/aws/mac-test.sh` | macOS E2E test runner via SSM (dedicated Mac instance) |

## Usage

### Interactive (default)

```bash
bash scripts/openclaw-setup.sh
```

Prompts for model provider, API keys, channels, and gateway port.

### Non-interactive (CI/fleet)

```bash
OC_PROVIDER=4 \
OC_PROVIDER_NAME=trendmicro-aiendpoint \
OC_BASE_URL=https://api.example.com/v1 \
OC_MODEL_ID=claude-4.6-sonnet \
OC_CHANNELS=slack \
OC_PORT=18789 \
bash scripts/openclaw-setup.sh --non-interactive --skip-install
```

### Dry run

```bash
bash scripts/openclaw-setup.sh --dry-run
```

Prints every command without executing.

### Run tests

```bash
for t in scripts/test/test-T*.sh; do bash "$t"; done
```

### E2E test on EC2

Launches a spot instance, clones the repo, and runs all tests on clean Ubuntu 24.04:

```bash
bash scripts/aws/ec2-test.sh launch     # Create keypair + spot instance (~$0.003/hr)
bash scripts/aws/ec2-test.sh test       # Run dry-run + test suites remotely
bash scripts/aws/ec2-test.sh teardown   # Delete everything
```

Requires AWS CLI configured. Uses t3.micro spot in us-east-2 by default.

### E2E test on macOS

Runs tests on a dedicated Mac instance via SSM (no SSH key needed):

```bash
bash scripts/aws/mac-test.sh info       # Show instance details + environment
bash scripts/aws/mac-test.sh test       # Run all dry-runs + test suites
bash scripts/aws/mac-test.sh report     # Same as test, saves report to reports/
```

Validated on macOS 15.7.3 (arm64) with Bash 3.2.57.

## Why Use It

- **No JSON corruption** -- all config via `openclaw config set`, never direct edits
- **Secrets never in config** -- API keys in `~/.openclaw/.env` with env var references
- **Atomic model definitions** -- providers set as complete JSON blocks, not field-by-field
- **Repeatable** -- same script works for fresh installs, recovery, and fleet deployments

## Project Structure

```
openclaw-setup/
  .github/
    publish.json              # GitHub account config (grobomo, public)
    workflows/
      secret-scan.yml         # CI secret scanning on push/PR
  docs/
    research.md               # Consolidated research from 7 sources
    setup-log.md              # Timestamped setup commands + root cause
  scripts/
    openclaw-setup.sh         # Main setup script
    aws/
      ec2-test.sh             # EC2 spot launcher for E2E testing
      ec2-spot-template.yaml  # CloudFormation template
    test/
      test-T001-*.sh          # Project scaffolding tests
      test-T002-*.sh          # Secret scan tests
      ...                     # 20 test suites total
  skill/
    SKILL.md                  # Claude Code skill definition
  TODO.md                     # Task tracker
```
