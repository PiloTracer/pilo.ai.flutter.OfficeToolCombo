# NEXT — OfficeToolCombo

**Active pointer:** Re-approve master plan Revision 2 (`status: Approved` in `.work.flutter/plans/full/20260802-full-plan.md`)

**Session note (2026-08-02):** Complex fixtures in `fixtures/report_consolidator/complex/`; output folder picker persists via SharedPreferences. Regenerate: `dart run tool/generate_consolidator_fixtures.dart`.

**Recommended next:**
1. Operator: set master plan front matter `status: Approved` (restores implementation-ready)
2. `@flutter-feature-spec approve` for SPEC-000…SPEC-006 (or review first)
3. Close remaining F1 gaps (F1-T2 migration, F1-T8 typed header-mismatch failures, widget/integration tests, NFR10)
4. `@flutter-verify milestone - F1`

## Intake queue

- 2026-08-02 · F1 · column totals + complex fixtures + output folder persist → FLT-7/8 (done)
- 2026-08-02 · cross-cutting · "buyer-ready five tools + hard en/es locale persist" → foundation continue + plan revise + SPECs (done)
- 2026-08-02 · local · consolidator row-count footer → implemented FLT-5 (done)
