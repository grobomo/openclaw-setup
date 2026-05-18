# OpenClaw Setup - TODO

## From Publishable Audit (2026-05-11)


<!-- See TODO-COMPLETED.md for history -->

## Integration Notes (T028)
- **openclaw-skill** (grobomo/openclaw-skill): Companion skill with pending T003 (marketplace publish) and T005 (hermes gateway). Not blocked by this project.
- **Fleet deployment**: --non-interactive + OC_* env vars enables fully automated provisioning. Ready for use in hook-runner fleet scripts or CI/CD pipelines.
- **Marketplace**: Plugin live on grobomo/claude-code-skills (PR #21 merged). No further marketplace work needed.
- **Cross-project**: No dependencies on this project from other grobomo repos. Self-contained.

## Phase 23: Webhook Integration
- [ ] T084: Add `setup_webhooks()` function to openclaw-setup.sh — deploys webhook server patches, creates Graph subscriptions, sets up renewal cron and watchdog. Integration function drafted in grobomo/teams-webhooks `patches/openclaw-setup-integration.sh`. Slot after `start_and_verify()` in main().
