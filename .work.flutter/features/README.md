# Feature SPECs

One directory per feature: `<slug>/YYYYMMDD-SPEC.md`, optionally with `PROBE_LEDGER.md`.

A SPEC is the **contract between intent and implementation**. Shape and rules: [`FEATURE_SPEC_STANDARD`](../standards/20260802-FEATURE_SPEC_STANDARD.md). Written by `@flutter-feature-spec`.

**Only an approved SPEC may be implemented.** `@flutter-implementation` reads the SPEC before writing code, and `@flutter-verify` audits the result against it.

---

## Index

| Slug | SPEC | Feature id | Status | Milestone | Last updated |
|------|------|-----------|--------|-----------|--------------|
| `home` | `20260802-SPEC.md` | FT-00 | Review | F0 | 2026-08-02 |
| `report_consolidator` | `20260802-SPEC.md` | FT-01 | Review | F1 | 2026-08-02 |
| `barcode_inventory` | `20260802-SPEC.md` | FT-02 | Review | F2 | 2026-08-02 |
| `document_factory` | `20260802-SPEC.md` | FT-03 | Review | F3 | 2026-08-02 |
| `price_monitor` | `20260802-SPEC.md` | FT-04 | Review | F4 | 2026-08-02 |
| `scheduled_backup` | `20260802-SPEC.md` | FT-05 | Review | F5 | 2026-08-02 |
| `settings` | `20260802-SPEC.md` | FT-06 | Review | F0 | 2026-08-02 |

---

## Lifecycle

`Draft` → `Review` → **`Approved`** → `Implemented` → (`Superseded`)

After approval, changes **append** as amendments. The original body is never rewritten — the amendment trail is how anyone reconstructs why the behaviour changed, and it is the first thing you want during an incident.

---

## The test of a good SPEC

Two competent engineers implement it independently and produce behaviourally equivalent software. If they would diverge, there is a gap.

The gaps are almost never in the happy path. They are in §6 (the six UI states), §9 (error handling) and §15 (acceptance criteria) — which is why those three sections are where `@flutter-feature-spec review` spends its attention.
