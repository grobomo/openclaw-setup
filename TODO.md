# OpenClaw Setup - TODO

## Phase 1: Project Init
- [x] Create TODO.md
- [x] Initialize git repo with local config (grobomo)
- [x] T001: Create .github/publish.json — grobomo public repo config
- [x] T002: Create secret-scan workflow — CI guard for public repo
- [x] T003: Push to GitHub — grobomo/openclaw-setup created and pushed

## Phase 2: Research
- [x] Fetch official OpenClaw docs (getting-started, configuration)
- [x] Search Reddit for OpenClaw gotchas and tips (blocked by Anthropic crawler)
- [x] Search web for setup guides and common issues
- [x] T004: Document findings in docs/research.md — consolidated from 7 sources
- [x] T005: Check current OpenClaw state in WSL — config missing, gateway stopped

## Phase 3: Document Current Setup
- [x] T006: Document every command run during OpenClaw setup — setup-log.md
- [x] T007: Log all config changes — tracked in setup-log.md + git
- [x] T008: Create setup-log.md with timestamped entries and root cause

## Phase 4: Build Automation
- [x] Create cross-platform install script (scripts/openclaw-setup.sh)
- [x] Create config templating via openclaw config set (no direct JSON edits)
- [x] Create channel setup automation (slack, telegram, discord, signal)
- [x] Create preferences interview (interactive prompts)
- [x] Secret storage in ~/.openclaw/.env with chmod 600

## Phase 5: Skill Packaging
- [x] SKILL.md with triggers and usage (skill/SKILL.md)
- [ ] T009: Deploy OpenClaw from scratch in WSL — execute setup-log.md steps
- [ ] T010: Verify gateway running and doctor clean
- [ ] T011: Merge worktree branch to main and push
- [ ] T012: Publish skill to grobomo marketplace

## Phase 6: Live Deployment (Current)
- [ ] T009: Run setup commands in WSL to restore OpenClaw
- [ ] T010: Verify gateway, channels, and doctor status
- [ ] T011: Merge to main, clean up branches
- [ ] T012: Publish to marketplace
