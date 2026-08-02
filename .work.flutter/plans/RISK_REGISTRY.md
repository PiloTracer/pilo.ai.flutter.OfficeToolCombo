# Risk registry — OfficeToolCombo

Things that could go wrong, what they would cost, and what changes because of them.

**A risk that changes nothing about the plan was not a risk.** Every entry names its sequencing consequence — the thing done differently because the risk exists. Without that column this file is a worry list.

---

## Register

| # | Risk | Likelihood | Impact | Score | Mitigation | Sequencing consequence | Trigger | Owner | Status |
|---|------|-----------|--------|-------|------------|------------------------|---------|-------|--------|
| RSK-001 | `excel` package unmaintained or fails on real workbooks | medium | high | high | F1 corpus spike; document `spreadsheet_decoder` read fallback in ADR if needed | F1 moved immediately after F0 before F3 | > 10% parse failure on sample set | Implementer | open |
| RSK-002 | Desktop notification parity differs (especially Linux DEs) | medium | medium | medium | F4 OS matrix spike; fallback in-app banner | F4 before F5; notification spike in F4 week 1 | Notification silent on target DE | Implementer | open |
| RSK-003 | Background price poll throttled or suspended on Windows/macOS sleep | medium | medium | medium | Document "best effort" in SPEC; resync on resume | F4 includes wake/resume tests | Missed alerts after sleep | Implementer | open |
| RSK-004 | Large xlsx merge blocks UI isolate | low | high | medium | Run merge in isolate; progress ViewModel | F1 architecture review before implementation | Frame budget exceeded in profile | Implementer | open |
| RSK-005 | drift migration defect loses inventory | low | high | medium | Migration tests from v1; backup before migrate | F0 migration test gate in CI | Failed migration in test | Implementer | open |
| RSK-006 | Dev host lacks sudo for apt — toolchain drift | medium | low | low | Document `/mnt/work/sdks/env.sh` in DOCS_FLUTTER_STACK | CI pins same Flutter as local | CI/local analyze mismatch | Operator | open |
| RSK-007 | Client paths logged accidentally | medium | high | high | Redacting logger; `@flutter-security audit` each milestone | F0 logging module before any file IO feature | Secret scan / path in log fixture | Implementer | open |
| RSK-008 | Install size exceeds 80 MB with PDF + sqlite native | low | medium | low | `--analyze-size` each milestone; defer heavy fonts | F6 size gate before release | Linux artifact > 80 MB | Implementer | open |

**Likelihood / Impact:** low · medium · high. **Score:** the product, used only for ordering.

**Sequencing consequence:** e.g. "the payment integration moves to F1 so it fails while there is still time to change approach". This is why the riskiest technical unknown goes early.

**Trigger:** the observable event that means the risk has materialised and the contingency starts. Deciding this in advance is the difference between a plan and a reaction.

---

## Materialised

| # | Risk | When | Actual impact | Response | Lesson |
|---|------|------|---------------|----------|--------|

---

## Categories worth checking

Prompts, not a checklist to fill mechanically.

| Category | Typical risks |
|----------|---------------|
| Technical | Unproven integration, platform limitation, performance target, unmaintained dependency |
| Data | Migration on shipped devices, sync conflicts, volume growth, loss |
| Platform | Store rejection, policy change, OS release, permission tightening |
| Security | Credential exposure, dependency vulnerability, compliance finding |
| Product | Requirements shifting, unvalidated assumption, unclear success measure |
| Delivery | Single point of knowledge, dependency on another team, deadline versus scope |
| Operational | No rollback path, unverified crash reporting, no on-call |

---

## Rules

1. Every risk has an owner. "The team" is nobody.
2. Every risk names its sequencing consequence, or it is deleted.
3. High-score risks are addressed in the earliest milestone that can address them.
4. Mitigations are actions with a due point, not intentions.
5. Risks carry into the master plan §17 with their consequences intact.
