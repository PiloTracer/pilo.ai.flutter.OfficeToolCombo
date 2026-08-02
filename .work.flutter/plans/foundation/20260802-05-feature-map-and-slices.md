# 05 — Feature map and slices

**Status:** Complete   **Phase:** P4/P6   **Updated:** 2026-08-02

---

## 1. Feature inventory

| ID | Feature | Priority | Acceptance (one line) | Depends on | SPEC |
|----|---------|----------|------------------------|------------|------|
| FT-00 | Home shell & navigation | P0 | User lands on home with five labeled tool entries and can reach each tool and return | — | `.work.flutter/features/home/` (F0) |
| FT-01 | Report consolidator | P0 | User selects a folder of `.xlsx` files and receives one merged `.xlsx` plus a list of files that failed | F0 | `.work.flutter/features/report_consolidator/` |
| FT-02 | Barcode inventory | P0 | Scanner wedge input stays focused; scan updates stock in DB and shows current quantity | F0 | `.work.flutter/features/barcode_inventory/` |
| FT-03 | Document factory | P0 | User picks template + data sheet and receives personalized PDFs with per-row errors listed | F0 | `.work.flutter/features/document_factory/` |
| FT-04 | Price monitor | P0 | Enabled watch notifies via OS notification when price crosses threshold; offline state visible without network | F0 | `.work.flutter/features/price_monitor/` |
| FT-05 | Scheduled backup | P0 | User configures daily zip of a folder with dated archive name; manual run works | F0 | `.work.flutter/features/scheduled_backup/` |
| FT-06 | Settings & AppSettings | P0 | User changes locale, theme, poll interval, retention | F0 | `.work.flutter/features/settings/` |
| FT-07 | Accessibility polish | P0 | All P0 screens pass keyboard/semantics/200% scale checks | F1–F5 | Cross-cutting F6 |
| FT-08 | Release packaging | P0 | Installable desktop artifacts for linux/macos/windows within size budget | F0–F6 | Release runbook F6 |

**P1 (post-v1 candidates — not in v1 milestones):** cloud backup destination, multi-template library UI, inventory CSV export, custom cron beyond daily.

---

## 2. Milestone candidates

| Milestone | Theme | Features | Depends on | Demoable outcome |
|-----------|-------|----------|------------|------------------|
| **F0** | Skeleton | FT-00, FT-06 (minimal), DI, router, theme, drift bootstrap | — | App runs on Linux/macOS/Windows; home shows five tools; empty tool screens navigable; CI analyze+test green |
| **F1** | Consolidator | FT-01 | F0 | Operator merges sample xlsx folder → one output + failure list |
| **F2** | Inventory | FT-02 | F0 | Operator scans barcodes; quantities persist across restart |
| **F3** | Document factory | FT-03 | F0 | Operator generates PDF batch from template + sheet |
| **F4** | Price monitor | FT-04 | F0 | Operator adds watch; stubbed price triggers notification |
| **F5** | Backup | FT-05 | F0 | Operator schedules daily zip; manual run produces dated archive |
| **F6** | Polish / a11y / release | FT-07, FT-08 | F1–F5 | Accessibility audit clean; compressed artifact ≤ 80 MB; es/en complete |

---

## 3. Slice rationale

| Order | Rationale |
|-------|-----------|
| F0 first | Establishes router shell, Riverpod graph, drift migrations, and quality gates without product risk. Enables parallel tool work afterward. |
| F1 before F3 | Both touch Excel; consolidator validates `excel` package on real files early (see RSK-001). |
| F2 parallel-safe after F0 | Isolated drift feature; no Excel dependency. |
| F3 after F1 | Reuses Excel parsing learnings; PDF generation is separate risk. |
| F4 before F5 | Exercises dio, notifications, and background timers — platform parity issues surface before backup scheduling combines file IO + timers. |
| F5 late | Scheduled jobs depend on stable app lifecycle; less user-visible if delayed briefly. |
| F6 last | Accessibility and release require all surfaces to exist. |

**Deliberately late:** Release signing and store-like installers — acceptable because internal desktop distribution is primary.

---

## 4. Dependency graph (technical)

```
F0 (shell, DI, router, theme, db bootstrap)
 ├── F1 report_consolidator
 ├── F2 barcode_inventory
 ├── F3 document_factory
 ├── F4 price_monitor (dio + notifications)
 └── F5 scheduled_backup (archive + timer)
      └── F6 polish / a11y / release (depends on all product tools)
```

No feature depends on another product feature's implementation — only on F0 shared core. Optional shared Excel utility may live in `core/` after F1 if F3 needs it.

---

## 5. Not in scope for v1

| Item | Notes |
|------|-------|
| Mobile platforms | See doc 02 |
| Web client | See doc 02 |
| Multi-device sync | Local SoT only |
| User accounts / auth | Single desktop user |
| Plugin marketplace | Five fixed tools |
| Automated cloud upload | Compliance exclusion |
| RTL locales | Not required launch |
| HIPAA/PCI workflows | Out of compliance scope |
