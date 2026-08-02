# 02 — Platforms and constraints

**Status:** Complete   **Phase:** P1   **Updated:** 2026-08-02

---

## 1. Target platforms

| Platform | Min OS | Device classes | Ship in | Notes |
|----------|--------|----------------|---------|-------|
| Linux | Ubuntu 22.04+ / Pop!_OS equivalent | Desktop | F0 | Primary dev and reference platform |
| macOS | 12 (Monterey)+ | Desktop | F0 | Notifications + file picker parity verified in F4/F5 |
| Windows | 10+ | Desktop | F0 | Long-path and Defender scan awareness for zip backups |

---

## 2. Non-target platforms (and why)

| Platform | Status | Reason |
|----------|--------|--------|
| iOS | Explicit non-target v1 | Product is desktop office tooling; no mobile scanner wedge workflow |
| Android | Explicit non-target v1 | Same as iOS |
| Web | Explicit non-target v1 | Local filesystem and background jobs require desktop APIs |

---

## 3. Device reality

| Constraint | Value |
|------------|-------|
| Lowest-tier reference device | Linux desktop, 4-core CPU, 8 GB RAM, SSD (Pop!_OS 22.04 class) |
| Smallest supported width | 1024 logical px (single-column tool layout below this shows horizontal scroll on data tables only) |
| Max text scale supported | 200% |
| Dark mode | Required — follows system; both themes in F0 |
| Input | Keyboard + mouse primary; barcode wedge emulates keyboard |
| Background execution | Price monitor poll + scheduled backup use desktop-friendly timers/isolates; no mobile background modes |

---

## 4. Connectivity model

| Aspect | Decision |
|--------|----------|
| Mode | **Local-first offline read-write** for tools 1, 2, 3, 5. Tool 4 (price monitor) requires network for fetch; UI and other tools remain usable offline. |
| Conflict policy | n/a — single device, no multi-writer sync |
| Sync trigger | n/a — no cloud sync |
| Behaviour with no network at cold start | App opens to home shell; consolidator, inventory, document factory, and backup operate on local files/DB. Price watches show **offline** state and pause polling until connectivity returns. |
| Price poll default interval | 10 minutes (configurable in AppSettings) |

---

## 5. Localisation

| Aspect | Decision |
|--------|----------|
| Locales at launch | English (`en`), Spanish (`es`) |
| RTL required | No |
| Date/number/currency formatting source | `intl` with locale from AppSettings; money uses `Decimal` |
| Pseudo-localisation in CI | Yes — long-string pass on F6 before release |
| User-visible strings | All in `.arb` files; no hardcoded copy in widgets |

---

## 6. Accessibility baseline

Default: WCAG 2.2 AA per project `20260802-ACCESSIBILITY` standard (generated at P3 from framework template when F6 polish runs; interim rules recorded here).

| Requirement | Decision |
|-------------|----------|
| Keyboard | Every primary action reachable without pointer |
| Screen reader | Semantics labels on all primary actions across five tools + home |
| Text scale | Layouts tested at 200%; no clipped primary actions |
| Focus | Scanner field in inventory maintains focus policy without trapping unrelated navigation |
| Contrast | Theme tokens meet 4.5:1 normal text |

No deviations recorded.

---

## 7. Compliance and regulatory

| Regime | Applies | Implication |
|--------|---------|-------------|
| HIPAA | No | No health data processing |
| PCI | No | No payment card data |
| GDPR (EU users possible) | Partial — local-only | No upload; user controls files; privacy notice in release notes |
| Client business data in local files | Yes | Treat as **sensitive internal**; never upload; redact paths in logs |

---

## 8. Organisational constraints

| Constraint | Value |
|------------|-------|
| Approved-dependency policy | OSS commercial-use only; see `STACK.md` and ADR-001 |
| Pub mirror | pub.dev default |
| Signing custody | Operator holds desktop codesign keys per platform at release (F6) |
| Release cadence | Milestone-driven F0–F6; no fixed external date |
| Host constraints | Dev environment may lack sudo for apt; Flutter SDK via user-local toolchain (`/mnt/work/sdks/env.sh`) |
| Team | Solo / agent-assisted; accepts codegen (`build_runner`, freezed, riverpod_generator) |
| Logging | Never log full filesystem paths that may contain client identifiers; use hashed or basename-only identifiers in diagnostics |
