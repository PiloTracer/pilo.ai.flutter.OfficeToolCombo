# Unknowns — OfficeToolCombo

Questions with no answer yet. **An unknown recorded here is not a gap in the plan; an unknown filled with a plausible guess is.**

Every entry states what it blocks, so its cost is visible. An unknown that blocks nothing is a curiosity and should be closed or deleted.

---

## Open

| # | Unknown | Blocks | Owner | Needed by | Raised | Current workaround |
|---|---------|--------|-------|-----------|--------|--------------------|
| UNK-001 | Maximum folder size / file count for consolidator before UX degrades | F1 performance acceptance only | Implementer | F1 complete | 2026-08-02 | Proceed with reference 100-file target in NFR10; revise after spike |
| UNK-002 | Which Linux desktop environments receive price notifications reliably | F4 notification acceptance | Implementer | F4 complete | 2026-08-02 | In-app banner fallback in SPEC draft |
| UNK-003 | Windows code-signing certificate availability for release | F6 release artifact trust | Operator | F6 | 2026-08-02 | Unsigned internal builds until cert procured |

**Owner** is a person or a role, never "the team". **Needed by** is a phase, milestone or date, never "soon".

---

## Resolved

| # | Unknown | Answer | Date | Recorded in |
|---|---------|--------|------|-------------|
| UNK-R1 | Which state management and local store? | Riverpod 3 + drift/sqlite3 — locked | 2026-08-02 | `.work.flutter/decisions/20260802-001-technology-stack.md` |
| UNK-R2 | Mobile v1? | No — desktop linux/macos/windows only | 2026-08-02 | `20260802-02-platforms-and-constraints.md` §1–2 |

---

## Rules

1. An unknown in a document marked certified or approved is a contradiction — resolve it, or reduce the scope so it is no longer blocking, and why.
2. Working around an unknown is allowed; **pretending it is answered is not**. Record the workaround and what happens when the real answer arrives.
3. An unknown blocking a ★ probe dimension blocks its phase gate.
4. Resolutions are recorded where the decision lives (a foundation doc, a SPEC, an ADR) and referenced here — this file is the index, not the source of truth.
