# Assumptions — OfficeToolCombo

Things being treated as true without evidence. Each one is a bet, and each states what it costs if it loses.

An unrecorded assumption is indistinguishable from a fact until it fails — usually in the milestone that depends on it most.

---

## Register

| # | Assumption | Basis | If wrong | Impact | Validate by | Owner | Status |
|---|------------|-------|----------|--------|-------------|-------|--------|
| ASM-001 | The `excel` package reads and writes the xlsx variants our users have | STACK lock + operator stand-in 2026-08-02 | Consolidator needs alternate read library or CSV pre-step | F1 delayed 1–2 weeks | F1 spike on 20+ real customer workbooks | Implementer | open |
| ASM-002 | USB keyboard-wedge barcode scanners work on all three desktop OS targets without custom drivers | Industry norm for HID wedge | F2 requires per-OS input workaround | F2 UX degraded | Manual test matrix Pop/Ubuntu, macOS, Windows | Implementer | open |
| ASM-003 | `flutter_local_notifications` delivers actionable alerts on Linux/macOS/Windows for price threshold | Package docs + operator stand-in 2026-08-02 | F4 needs platform-specific notify fallback | F4 scope increase | F4 spike on each OS | Implementer | open |
| ASM-004 | Solo/agent-assisted team accepts codegen workflow (`build_runner`, freezed) | ADR-001, HANDOFF 2026-08-02 | Slower iteration if codegen conflicts | Ongoing friction | First F0 codegen CI run | Operator | accepted |
| ASM-005 | Users tolerate daily (not sub-hour) backup granularity | Product intent operator stand-in 2026-08-02 | Feature rejection by power users | Post-v1 cron enhancement | User feedback after F5 | Operator | open |
| ASM-006 | Reference Linux dev machine (`/mnt/work/sdks/env.sh`) represents minimum user hardware | HANDOFF host notes | Performance NFRs fail on older PCs | NFR1/NFR10 miss | Profile on 4-core/8GB machine before F6 | Implementer | open |
| ASM-007 | Buyer-ready v1 does not require cloud sync, multi-user accounts, or inventory CSV export | Operator 2026-08-02 commercial bar | Some prospects demand cloud before purchase | Post-v1 P1 backlog | Sales feedback after first demos | Operator | accepted |
| ASM-008 | Dual locale en/es covers the LatAm + bilingual office buyers targeted for v1 | Operator 2026-08-02 | Need additional locales | F6+ localisation milestone | Market feedback | Operator | open |

**Basis:** where it came from — a stakeholder statement, an industry norm, a previous project, or nothing but convenience. "Nothing but convenience" is a legitimate entry and a useful signal.

**If wrong:** the concrete consequence. "Rework the sync layer, roughly two weeks" beats "problems".

**Validate by:** the cheapest thing that would confirm or kill it, and when. An assumption nobody plans to test is a permanent risk wearing a different label.

**Status:** open · validated · invalidated · accepted (deliberately never testing it).

---

## Invalidated

Kept, not deleted. What was believed and why it was wrong is the most useful thing in this file for the next project.

| # | Assumption | How it failed | Cost | Date |
|---|------------|---------------|------|------|

---

## Common assumptions worth writing down

Recorded here because they are the ones most often left implicit, and among the most expensive when wrong:

- The API contract will not change during the build.
- Users have reliable connectivity.
- The data volume per user stays within the range we designed for.
- The third-party SDK will stay maintained and keep its licence.
- The design will not change materially after implementation starts.
- One developer's device performance represents the user base.
- The backend enforces the rules the client assumes it does.
- Store review will not object to what we are shipping.
