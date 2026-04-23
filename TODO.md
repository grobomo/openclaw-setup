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
- [x] T027: Dry-run mode verified E2E — all 5 providers work, channels configured, gateway wait skipped, no side effects
- [x] T028: Zoom out — integration audit complete, cross-project TODOs logged

## Integration Notes (T028)
- **openclaw-skill** (grobomo/openclaw-skill): Companion skill with pending T003 (marketplace publish) and T005 (hermes gateway). Not blocked by this project.
- **Fleet deployment**: --non-interactive + OC_* env vars enables fully automated provisioning. Ready for use in hook-runner fleet scripts or CI/CD pipelines.
- **Marketplace**: Plugin live on grobomo/claude-code-skills (PR #21 merged). No further marketplace work needed.
- **Cross-project**: No dependencies on this project from other grobomo repos. Self-contained.

## Phase 10: Deep Audit & Hardening
- [x] T029: Scan all 4 session logs — no incomplete tangents found, orphan agent dir is deployment artifact not project issue
- [x] T030: Run full test suite E2E — 20/20 suites, 92/92 assertions pass
- [x] T031: Gateway verified — restarted (pid 7166), port 18789, 401 on unauthenticated (correct)
- [x] T032: Code review — fix bash 3.2 empty array expansion (CHANNEL_LIST), add compat test assertion
- [x] T033: README updated — test counts 15→20 suites, 83→92 assertions

## Phase 11: EC2 E2E Test
- [x] T034: Launch EC2 spot instance (t3.micro, Ubuntu 24.04, NodeSource Node.js 24)
- [x] T035: Dry-run all 5 providers on clean Linux — Anthropic, OpenAI, OpenRouter, Custom, Ollama all pass
- [x] T036: Test suites on EC2 — 79/81 pass (2 git-config tests expected to fail on fresh clone)
- [x] T037: Teardown — stack deleted, keypair cleaned up, zero resources remaining

## Phase 12: Final Audit & Expansion -- COMPLETE
- [x] T038: Scan session logs for incomplete tangents — 5 .jsonl files scanned, no deferred work found
- [x] T039: Run full test suite — 20/20 suites, 93/93 assertions pass
- [x] T040: Verify live gateway health — pid 9806, port 18789, 401 on unauth (correct)
- [x] T041: Final code review — EC2 scripts clean, no security issues, no hardcoded paths
- [x] T042: README updated — assertion count 92→93, added EC2 E2E test docs and project structure
