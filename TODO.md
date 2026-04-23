# OpenClaw Setup - TODO

## Phase 1: Project Init -- COMPLETE
- [x] Create TODO.md
- [x] Initialize git repo with local config (grobomo)
- [x] T001: Create .github/publish.json -- grobomo public repo config
- [x] T002: Create secret-scan workflow -- CI guard for public repo
- [x] T003: Push to GitHub -- grobomo/openclaw-setup created and pushed

## Phase 2: Research -- COMPLETE
- [x] Fetch official OpenClaw docs (getting-started, configuration)
- [x] Search web for setup guides, gotchas, production failures
- [x] T004: Document findings in docs/research.md -- consolidated from 7 sources
- [x] T005: Check current OpenClaw state in WSL -- config missing, gateway stopped

## Phase 3: Document Current Setup -- COMPLETE
- [x] T006: Document every command run during OpenClaw setup -- setup-log.md
- [x] T007: Log all config changes -- tracked in setup-log.md + git
- [x] T008: Create setup-log.md with timestamped entries and root cause

## Phase 4: Build Automation -- COMPLETE
- [x] Create cross-platform install script (scripts/openclaw-setup.sh)
- [x] Create config templating via openclaw config set (no direct JSON edits)
- [x] Create channel setup automation (slack, telegram, discord, signal)
- [x] Create preferences interview (interactive prompts)
- [x] Secret storage in ~/.openclaw/.env with chmod 600

## Phase 5: Skill Packaging -- COMPLETE
- [x] SKILL.md with triggers and usage (skill/SKILL.md)
- [x] All 8 test suites passing (45 assertions)

## Phase 6: Live Deployment -- COMPLETE
- [x] T009: Deploy OpenClaw in WSL -- gateway mode, RDSEC provider, model defs, agent defaults
- [x] T010: Verify gateway running (pid 3084), config valid, model trendmicro-aiendpoint/claude-4.6-sonnet
- [x] T011: Merge to main, push to grobomo/openclaw-setup

## Phase 7: Remaining
- [ ] T012: Publish skill to grobomo marketplace
- [ ] T013: Re-add Slack channel IDs for specific channels (requireMention config)
- [ ] T014: Re-add Signal channel config
- [ ] T015: Re-add plugins (coconut-guardrails, hook-runner-gates, mfa-skill-guard)
- [ ] T016: Re-add MCP server config (mcp-manager)
- [ ] T017: Update setup script to handle model definitions atomically (learned from validation errors)
- [ ] T018: Add --non-interactive mode to setup script for CI/fleet deployments
