# 01 — Product and scope

**Status:** Complete   **Phase:** P0/P4   **Updated:** 2026-08-02 (commercial bar + bilingual amendment)

---

## 1. Name

**OfficeToolCombo**

---

## 2. Intent (one sentence)

One desktop Flutter application that lets non-technical office staff run five **paid, buyer-ready** operational jobs—consolidate Excel reports, track inventory with a barcode scanner, batch-generate PDF documents, monitor prices in the background, and schedule dated folder backups—without opening a terminal or installing separate tools, in **English or Spanish**, with the language choice surviving restarts.

---

## 3. Jobs to be done

| # | Persona | Job | Today's workaround | Success signal |
|---|---------|-----|-------------------|----------------|
| J1 | Office coordinator | Merge a folder of `.xlsx` reports into one clean workbook and see which files failed | Manual copy-paste in Excel or a one-off script someone else wrote | One output file on a chosen path plus a readable failure list for broken/mismatched files; no terminal; demoable in under 5 minutes |
| J2 | Stock clerk | Scan barcodes into inventory and look up stock on the floor | Spreadsheet or paper log; re-keying into Excel | Scanner field always ready and cleared after each scan; unknown barcodes creatable; stock persists across restart |
| J3 | Admin assistant | Turn Excel rows plus a **user-owned** template (logo/fields) into personalized PDFs | Mail merge in Word or manual PDF editing | Field mapping without code; batch PDFs + per-row errors; progress visible for multi-minute runs |
| J4 | Buyer / ops | Watch product prices and get notified when they cross thresholds | Bookmark + manual refresh or browser extension | Multi-watch CRUD from UI; background poll; OS notification while app minimized; offline badge |
| J5 | Office manager | Zip a working folder on a daily schedule with a dated archive name | Manual zip or cron job maintained by IT | Source/destination/hour from UI; manual run; last-run status; dated archives never overwrite yesterday |

---

## 4. Users and personas

| Persona | Context | Primary tools | Notes |
|---------|---------|---------------|-------|
| Office coordinator | Desk, dual monitor, moderate Excel literacy | Report consolidator, document factory | Needs clear error lists, not stack traces |
| Stock clerk | Standing at shelf, USB barcode wedge keyboard | Barcode inventory | Keyboard-wedge input must stay focused; minimal navigation |
| Admin assistant | Desk, template-driven correspondence | Document factory | Batch jobs may run minutes; progress must be visible |
| Buyer / ops | Desk, occasional network | Price monitor | Tolerates stale quotes when offline; must not block other tools |
| Office manager | Desk, owns backup destination | Scheduled backup | Trusts dated archives; no sudo or shell |

**Roles:** Single application shell; all personas see the same five tool entries on the home screen (F0). No role-based hiding in v1.

**Explicit non-users:** Mobile field workers (no iOS/Android v1), developers expecting CLI workflows, users who need cloud sync or multi-device inventory.

---

## 4b. Commercial product bar (buyer-ready)

Operator decision 2026-08-02: plans and SPECs must close **gaps beyond the ideas transcript** so each tool is something a company would pay for—not a demo of a technical gesture.

| Rule | Meaning |
|------|---------|
| Zero terminal | Every paid job is completable with folder pickers, forms, and one primary action button |
| One job done well | Each tool finishes a complete pain (not a half-script); failure modes are listed, not silent |
| Trust surface | Partial failures, offline, and progress are always visible in the operator’s language |
| Language | Full UI in `en` and `es`; chosen locale persists across process restarts (non-cuttable) |
| Demoability | A stranger can complete the happy path of each tool in ≤ 5 minutes on a sample corpus |
| Sellable extras (v1 must) | Consolidator: output path + failure trust · Inventory: always-ready focus + unknown-SKU create · Documents: user template + field mapping · Prices: multi-watch UI + OS alert · Backup: schedule UI + last-run status |

**Not required for v1 commercial bar (remain P1):** cloud destinations, inventory CSV export, multi-template library, sub-daily cron, collaborative sync.

---

## 5. Non-goals (explicit)

| Non-goal | Reason |
|----------|--------|
| iOS, Android, Web v1 | Desktop-only product decision; see doc 02 |
| Cloud upload of client files | Local business data must not leave the machine |
| Multi-user server sync | Local-first; no backend in v1 |
| HIPAA / PCI compliance scope | Product does not handle regulated health or card data |
| Terminal or script exposure to end users | Core product promise |
| Real-time collaborative editing | Out of scope for office batch tools |
| Custom macro language inside the app | Templates and Excel inputs stay in familiar formats |

---

## 6. Success metrics

| Metric | Baseline | Target | Measured how |
|--------|----------|--------|--------------|
| Cold start to home shell | Unknown (greenfield) | ≤ 2500 ms on reference Linux desktop | `--trace-startup`, `@flutter-perf startup` |
| Crash-free sessions | n/a | ≥ 99% | Desktop crash reporter after F0 wiring |
| Line coverage on `lib/` (excl. generated) | 0% | ≥ 80% | `flutter test --coverage`, `@flutter-test coverage` |
| Consolidator success rate | n/a | Operator completes merge with failure list for bad inputs | Manual acceptance on sample corpus |
| Inventory scan latency | n/a | Lookup ≤ 200 ms after scan on reference device | Integration test + profile |
| Document factory throughput | n/a | ≥ 50 PDFs/min on reference desktop for simple template | Benchmark script in F3 |
| Price notification latency | n/a | Alert within one poll interval (default 10 min) after threshold cross | Integration test with stubbed HTTP |
| Backup reliability | n/a | Scheduled daily zip succeeds or surfaces actionable error | Integration test + manual soak |
| Install size (compressed desktop artifact) | n/a | ≤ 80 MB | `flutter build` size analysis |
| Accessibility on P0 screens | n/a | Keyboard + screen reader labels on all primary actions; usable at 200% text scale | `@flutter-a11y audit` |
| Locale completeness | n/a | 100% of user-visible strings present in both `en` and `es` ARBs at release | Pseudo-l10n CI + manual spot check |
| Locale persistence | n/a | Selected language still applied after quit and cold start | Integration test settings → restart |

---

## 7. Open questions → UNKNOWNS.md

| Topic | Disposition |
|-------|-------------|
| Maximum `.xlsx` folder size for consolidator | Recorded as UNK-001; F1 spike will bound |
| Linux desktop notification parity for price alerts | Recorded as UNK-002; F4 platform spike |
| Whether `excel` package handles all customer workbook variants | Assumption ASM-001 + risk RSK-001; F1 validates on sample set |

No open questions block foundation certification; remaining items have owners and milestone hooks.
