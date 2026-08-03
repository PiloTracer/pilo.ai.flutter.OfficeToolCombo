# NEXT — OfficeToolCombo

**Active pointer:** close FL10N-T3 + FL10N-T6 → `@flutter-verify milestone - F2` → F3 document factory

**Session closed:** 2026-08-02 — F-L10N bilingual foundation landed (en/es UI, locale persists across restarts); full-codebase audit fixes (CSV hardening, import confirmation, Excel cell fidelity, mounted guards). Verified: analyze clean, 91/91 tests, linux build green.

**Recommended next (in order):**
1. **FL10N-T3** `integration_test/locale_persist_test.dart` — set es, restart, assert es
2. **FL10N-T6** `tool/pseudo_l10n_check.sh` — CI gate for hardcoded strings
3. Operator approvals (blocking): master plan `status: Approved` · SPECs SPEC-000…006 · **router l10n wiring** (`lib/core/router/app_router.dart` is a protected surface — placeholder titles + error page still English)
4. `@flutter-verify milestone - F2` — close integration test + coverage gaps
5. `@flutter-implementation - F3` — F-L10N string gate now satisfied

**F1 deferred:** F1-T2 migration (protected), F1-T8 typed failures, integration tests, NFR10

## Intake queue

- 2026-08-02 · **F-L10N** · bilingual foundation → **code done** (T1/T2/T4/T5); T3/T6 remain
- 2026-08-02 · audit · LOW findings reported in HANDOFF (footer width, isolate progress, stepper focus, upsert id)
- 2026-08-02 · F2 · QR/barcode inventory multi-modal input → FLT-9 (done)
- 2026-08-02 · F1 · column totals + complex fixtures + output folder persist → FLT-7/8 (done)
