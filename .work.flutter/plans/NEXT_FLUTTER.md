# NEXT — OfficeToolCombo

**Active pointer:** `@flutter-verify milestone - F2` then **`@flutter-implementation - F-L10N`** (blocking before F3–F5)

**Session closed:** 2026-08-02 — F2 inventory UX fixes (image decode isolate, dialog focus, quantity stepper, manual entry).

**Recommended next (in order):**
1. `@flutter-verify milestone - F2` — close integration test + coverage gaps
2. **`@flutter-implementation - F-L10N`** — bilingual foundation (**required before F3/F4/F5**)
   - FL10N-T1: ARB scaffold + `flutter gen-l10n` + app delegates
   - FL10N-T2: Settings locale picker + persistence (en/es)
   - FL10N-T3: `integration_test/locale_persist_test.dart`
   - FL10N-T4: Wire F1 consolidator strings
   - FL10N-T5: Wire F2 inventory strings
   - FL10N-T6: `tool/pseudo_l10n_check.sh` CI gate
3. `@flutter-feature-spec approve` or amend SPEC-002 for expanded F2 scope
4. **Do not start F3, F4, or F5** until F-L10N exit gate passes (see master plan §11.1)

**F1 deferred:** F1-T2 migration, F1-T8 typed failures, widget/integration tests, NFR10

## Intake queue

- 2026-08-02 · **F-L10N** · bilingual foundation before remaining utilities → **planned, not started** (master plan §11.1)
- 2026-08-02 · F2 · QR/barcode inventory multi-modal input → FLT-9 (done)
- 2026-08-02 · F1 · column totals + complex fixtures + output folder persist → FLT-7/8 (done)
- 2026-08-02 · cross-cutting · "buyer-ready five tools + hard en/es locale persist" → foundation continue + plan revise + SPECs (done)
- 2026-08-02 · local · consolidator row-count footer → implemented FLT-5 (done)
