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

## Phase 13: macOS E2E Test (AWS Mac Instance) -- COMPLETE
- [x] T049: SSM access to mac2.metal verified — macOS 15.7.3, arm64, Bash 3.2.57, Node.js installed via binary
- [x] T050: All 5 provider dry-runs pass on macOS Bash 3.2.57 (fixed ${VAR^^} → tr uppercase)
- [x] T051: 80/82 test assertions pass (2 git-config expected failures on fresh clone)
- [x] T052: Test report saved to reports/macos-e2e-*.log with full output

## Phase 14: Root Cause Investigation — Dreaming Config Crash (2026-04-22)

### Background (from Joel, 2026-04-23)
OpenClaw was offline for 12+ hours. Joel investigated and found `openclaw.json` was corrupted:
- Coconut had tried to enable dreaming in `openclaw.json` directly
- The resulting JSON failed linting at the memory/dreaming config block
- Even after Joel manually added dreaming per official docs, JSON linting errors persisted
- Joel moved the file to `openclaw.json.bak04232026` and had Claude Code (this instance) rebuild from scratch
- Claude Code repaired the config and gateway came back online

### Findings (2026-04-23, Claude Code investigation)
- [x] T043: **Root cause**: Missing `}` to close `agents` block at line 130 of bak_04232026. The `agents.defaults` section closed properly, but `agents` itself was never closed — `channels`, `plugins`, `meta`, `logging`, `hooks`, and `mcp` all nested inside `agents`. Brace count: 91 opens, 90 closes. JSON parse error at EOF: "Expecting ',' delimiter". **What Claude Code did to fix**: Rebuilt config from scratch using `openclaw config set` commands (audit log shows 20+ `config set` calls from `scaffolding` cwd at 16:16-16:37 UTC). This discarded all advanced features (memorySearch, signal, active-memory, custom guardrail rules, mfa-skill-guard, extra Slack channels, plugin load paths).
- [x] T044: **Correct dreaming syntax**: `openclaw config set plugins.entries.memory-core.config.dreaming.enabled true`. Schema path: `plugins.entries.memory-core.config.dreaming.enabled: true`. The backup's dreaming config was correct — it was NOT the cause of the crash.
- [x] T045: **Dreaming schema was NOT wrong.** Coconut used correct field names for dreaming (`plugins.entries.memory-core.config.dreaming.enabled`). The corruption was a structural brace issue in the `agents` block, likely introduced when `memorySearch` was added to `agents.defaults` via direct JSON edit instead of `openclaw config set`.
- [x] T046: Added `validate_config()` function to `scripts/openclaw-setup.sh` — runs after all config writes, uses `node -e JSON.parse()` to catch invalid JSON before gateway start. Test assertions added to T026 suite (14 assertions, all pass).
- [x] T047: Dreaming re-enabled via `openclaw config set plugins.entries.memory-core.config.dreaming.enabled true`. Gateway restarted, memory-core loaded among 9 plugins. Gateway logs confirm config change detected and applied.
- [x] T048: Added "Dreaming Config — CORRECT SYNTAX DOCUMENTED" decision to `~/.openclaw/workspace/DECISIONS.md` with root cause, correct schema, and DO-NOT rules (never edit JSON directly, always use `openclaw config set`).

## Phase 15: Final Audit & Hardening -- COMPLETE
- [x] T053: Scan 7 session logs — no incomplete tangents, no deferred work
- [x] T054: Full test suite — 20/20 suites, 96/96 assertions pass, 0 failures
- [x] T055: Code review — no eval, no rm -rf, no FIXME/HACK/TODO in code, bash syntax valid, 588 lines clean
- [x] T056: validate_config E2E — 5/5 tests pass in WSL (valid JSON accepted, missing brace caught, brace mismatch caught, real crash pattern caught, live config valid)
- [x] T057: README assertion count verified correct at 96

## Phase 16: Config Backup/Restore — Crash Recovery Gap -- COMPLETE
- [x] T058: Created `scripts/config-backup.sh` — backup with metadata wrapper (timestamp, sha256, hostname)
- [x] T059: Restore from backup with JSON validation, pre-restore safety backup, rollback on failure
- [x] T060: Diff command — compares top-level keys and sizes between current and backup
- [x] T061: Test suite — 12/12 assertions (existence, syntax, all commands, safety checks, no eval)
- [x] T062: README updated — added config-backup docs, usage section, updated test counts to 21 suites / 108 assertions

## Phase 17: Post-Completion Maintenance -- COMPLETE
- [x] T063: Scan 8 session logs — no incomplete tangents, all prior work resolved
- [x] T064: Full test suite — 21/21 suites, 108/108 assertions pass, 0 failures
- [x] T065: config-backup.sh E2E in WSL — backup, list, diff, restore all work, JSON validated
- [x] T066: Remote branches clean — only origin/main, 2 local worktrees already removed

## Phase 18: Plugin Trust Pinning — Security Hardening -- COMPLETE
- [x] T068: Added pin_plugin_trust() — detects installed plugins, sets plugins.allow as JSON array
- [x] T069: OC_PLUGINS_ALLOW env var for non-interactive mode, documented in header
- [x] T070: 5 new test assertions — function exists, called in configure, plugins.allow set, env var documented and used
- [x] T071: Committed and pushed, 21 suites / 113 assertions / 0 failures

## Phase 19: macOS Compatibility Fix -- COMPLETE
- [x] T072: Replaced grep -oP with POSIX sed in pin_plugin_trust — works on macOS Bash 3.2
- [x] T073: Full test suite — 21/21 suites, 113/113 assertions, 0 failures
