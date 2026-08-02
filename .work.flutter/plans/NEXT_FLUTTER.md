# NEXT — OfficeToolCombo

**Active pointer:** Re-approve master plan Revision 2 (`status: Approved` in `.work.flutter/plans/full/20260802-full-plan.md`)

**Recommended next:**
1. Operator: set master plan front matter `status: Approved` (restores implementation-ready)
2. `@flutter-feature-spec approve` for SPEC-000…SPEC-006 (or review first)
3. Close F1 gaps against expanded plan + SPEC-001 (F1-T2, F1-T7/T8 typed header-mismatch failure, widget/integration tests, NFR10)
4. `@flutter-verify milestone - F1`

**Session note (2026-08-02 close):** Fixtures under `.work.flutter/fixtures/report_consolidator/`; row-count footer in `WorkbookMerger` (FLT-5). Run app with `source /mnt/work/sdks/env.sh` then `flutter run -d linux`.

## Intake queue

- 2026-08-02 · cross-cutting · "buyer-ready five tools + hard en/es locale persist" → foundation continue + plan revise + SPECs (done)
- 2026-08-02 · local · consolidator row-count footer → implemented FLT-5 (done)
