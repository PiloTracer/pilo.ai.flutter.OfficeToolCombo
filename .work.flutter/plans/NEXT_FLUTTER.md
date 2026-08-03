# NEXT — OfficeToolCombo

**Active pointer:** `@flutter-verify milestone - F2` → **`@flutter-implementation - F3`** (document factory)

**Session closed:** 2026-08-02 — plan + SPECs Approved (implementation-ready), router l10n wired, FL10N-T3/T6 landed, LOW audit fixes (isolate progress, footer width, stepper focus). Verified: analyze clean, 95/95 tests + 1/1 integration, pseudo-l10n PASS, linux build green.

**Recommended next (in order):**
1. `@flutter-verify milestone - F2` — F2 gaps: on-device integration test F2-T5, coverage vs 80% floor
2. `@flutter-implementation - F3` — document factory (SPEC-003 Approved; F-L10N gate satisfied)
3. F1 residuals when touching consolidator: F1-T2 drift migration (protected — needs in-message approval), F1-T8 typed header-mismatch failure, NFR10 profile

**F1 deferred:** F1-T2 migration (protected), F1-T8 typed failures, F1-T6 integration test, NFR10

## Intake queue

- 2026-08-02 · **F-L10N** · bilingual foundation → **done (T1–T6 all landed)**
- 2026-08-02 · operator approvals → **done** (plan Rev 2–3 Approved; SPEC-000…006 Approved)
- 2026-08-02 · audit LOW → done: footer width, isolate progress, stepper focus · reported-only: drift upsertItem id re-key
- 2026-08-02 · hygiene · stray `thresholds_new.pnm` at repo root (debug artifact — delete if unwanted)
