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

## Phase 7: Polish & Publish -- COMPLETE
- [x] T012: Publish to grobomo marketplace (PR #21: grobomo/claude-code-skills) + README + explainer HTML
- [x] T013: Add Slack channel IDs with per-channel requireMention (4 channels configured)
- [x] T014: Signal channel support in setup script (no live account, deferred)
- [x] T015: Enable plugins -- coconut-guardrails, hook-runner-gates, memory-core
- [x] T016: MCP config validated clean (was empty in backup, nothing to restore)
- [x] T017: Atomic model defs via --json (prevents validation errors from field-by-field sets)
- [x] T018: Non-interactive mode (--non-interactive flag, OC_* env vars for CI/fleet)
- [x] T019: Clean up stale branches and worktree (4 branches deleted, 1 worktree removed)

## Phase 8: Verification & Hardening
- [x] T020: Run full test suite -- 15/15 suites, 78 assertions, 0 failures
- [x] T021: Gateway verified running (pid 5138), config valid after all changes
- [x] T022: Add .gitignore for workflow state, worktrees, setup logs
- [x] T023: Marketplace PR #21 merged -- 4/4 CI checks passed (secret scan, structure, LF, quality gate)

## Phase 9: Session Log Audit & E2E Validation
- [x] T024: Scan previous session logs for deferred/skipped/temporary work — no tangents found
- [x] T025: Run full test suite E2E — 15/15 suites, 78/78 assertions, gateway healthy (pid 5138)
- [x] T026: Code review — 6 fixes: eval→direct exec, add OpenAI/OpenRouter providers, redactSensitive on, env_set dedup helper, docs/ mkdir, document OC_CONTEXT_WINDOW/OC_MAX_TOKENS
- [ ] T027: Verify setup script works end-to-end on a clean WSL environment (dry-run mode)
- [ ] T028: Zoom out — integration with other grobomo projects, fleet deployment readiness
