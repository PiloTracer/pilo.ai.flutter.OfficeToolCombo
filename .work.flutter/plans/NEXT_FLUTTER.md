# NEXT — OfficeToolCombo

**Active pointer:** nothing blocking on the agent side — awaiting operator's deferred items; `@flutter-release certify` when signing lands

**Session closed:** 2026-08-02 — operator decisions recorded (plan Revision 4): SPEC-003/004/005 amendment-01 **ratified**; **F1-T2 closed as superseded**; F6-T6 signing, manual acceptance, and NFR3 startup **deferred to operator**. Plan + traceability verify still PASS.

**All agent-resolvable work is complete.** Gate: 387/387 tests · coverage 85.0% ≥ 80 · hygiene 0 BLOCKERs · pseudo-l10n PASS · 4/4 journeys · release 41 MB ≤ 80 MB · NFR10/11/12 measured PASS.

**Operator's deferred queue (their words, 2026-08-02):**
1. F6-T6 signed release artifacts — "I will work on this in a few days" (macOS/Windows hosts + signing keys)
2. Manual acceptance — "later": UNK-002 Linux DE matrix, macOS/Windows notification pass, screen-reader pass
3. NFR3 startup ≤ 2500 ms — "later": needs reference desktop with display

**Non-blocking code follow-ups (any future session):**
- docx template support for document factory
- F3 dirty-mapping discard prompt (needs PopScope in ToolShellScaffold)
- CJK template text → bundle a TTF for package:pdf (WinAnsi-only default)

**Verification commands (canonical for CI):**
- `flutter test --exclude-tags benchmark` (suite) · `flutter test --tags benchmark` (NFR timing, quiet host)
- `tool/test_integration.sh` (journeys — per-file; upstream flutter_tools bug #101031)
- `tool/pseudo_l10n_check.sh` · `dart run tool/benchmark_consolidator.dart` · `dart run tool/benchmark_document_factory.dart`

## Intake queue

- (empty — all intake resolved; awaiting operator's deferred items above)
