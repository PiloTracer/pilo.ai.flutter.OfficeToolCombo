# 03 — Architecture and NFRs

**Status:** Complete   **Phase:** P2/P5   **Updated:** 2026-08-02

**Prerequisite:** `.work.flutter/STACK.md` Status: Locked (2026-08-02)

---

## 1. Layering (View / ViewModel / Repository)

Stack alignment: **Riverpod 3** (state + DI), **go_router**, **drift**, **freezed**, **dio** (price monitor only).

| Layer | Contains | May depend on | Must never contain |
|-------|----------|---------------|--------------------|
| **View** (`presentation/…/*_view.dart`) | Widgets, layout, semantics, route callbacks | ViewModel (via Riverpod), theme, l10n | Repositories, DTOs, SQL, HTTP, `dart:io` file operations |
| **ViewModel** (`*_view_model.dart` / `@riverpod` notifiers) | Screen state, user intents, failure → UI state mapping | Domain repository **interfaces** | Other ViewModels, widgets, `BuildContext` (except injected callbacks for one-shot effects) |
| **Domain** (`domain/`) | Entities, repository interfaces, sealed failures, validation rules | Pure Dart only | Flutter, drift, dio, excel, pdf packages |
| **Data** (`data/`) | Repository implementations, DTOs, local/remote sources, mappers | Domain | Widgets, navigation |

**Dependency direction:** View → ViewModel → Domain ← Data.

**Composition root:** `lib/bootstrap.dart` wraps `ProviderScope`; `lib/app.dart` hosts `MaterialApp.router` with go_router. All repository and client providers registered in `lib/core/di/`.

**Feature modules:** `report_consolidator`, `barcode_inventory`, `document_factory`, `price_monitor`, `scheduled_backup`, plus `home` shell and `settings` in `lib/features/`.

---

## 2. Error strategy

**Two-track model** per `20260802-ARCHITECTURE_STANDARD.md`:

| Kind | Representation | Examples in OfficeToolCombo |
|------|----------------|----------------------------|
| Expected, actionable | Sealed `*Failure` returned or carried in ViewModel state | Invalid xlsx, template missing column, price fetch timeout, backup destination not writable |
| Unexpected | Logged + reported; user sees generic recovery | Assert in mapper, drift migration failure |

**Mapping rules:**

- `DioException`, parse errors, and filesystem errors are caught in **data** sources and mapped to domain failures at the repository boundary.
- ViewModels convert failures into the six UI states (loading, empty, partial, error, offline, success); Views never inspect exception types.
- File paths in error messages shown to users use basename + folder picker context, not full PII-bearing paths.
- Retry: idempotent reads (price fetch) retry with backoff; destructive writes (overwrite output xlsx) require explicit user confirmation.

**Global handlers:** `FlutterError.onError` and `PlatformDispatcher.instance.onError` wired in F0 bootstrap; crash reporter hooked before F6 release.

---

## 3. Dependency injection

| Aspect | Decision |
|--------|----------|
| Mechanism | Riverpod providers (`@riverpod` codegen + hand-written overrides) |
| Composition | `bootstrap.dart` → `ProviderScope` → `app.dart` |
| Scoping | App-lifetime: drift database, dio client, settings repository. Route-scoped: feature ViewModels via `autoDispose` where appropriate. |
| Test overrides | `ProviderScope(overrides: …)` in tests; no service locator |
| Clock / connectivity | `Clock` and `ConnectivityService` interfaces injected for price monitor and backup scheduling tests |

---

## 4. Cross-cutting concerns

| Concern | Location |
|---------|----------|
| Routing | `lib/core/router/app_router.dart` — shell route `/` with five child tool routes |
| Theming | `lib/core/theme/` — light/dark, density at 200% scale |
| l10n | `lib/core/l10n/` — `en`, `es` ARB |
| Local store | drift DB in `lib/core/storage/` — inventory, watches, jobs, settings |
| Background work | `price_monitor` isolate-friendly poll; `scheduled_backup` timer + work queue |
| Observability | Structured logger in `lib/core/logging/` — redacts paths and URLs with tokens |

---

## 5. Non-functional requirements

| ID | Category | Requirement | Target | Measured by |
|----|----------|-------------|--------|-------------|
| NFR1 | Startup | Cold start to first meaningful frame (home shell), reference Linux desktop | ≤ 2500 ms | `flutter run --trace-startup`, `@flutter-perf startup` |
| NFR2 | Frame budget | 99th-percentile frame build+raster during foreground scroll/interaction | ≤ 16 ms | `@flutter-perf profile`, DevTools |
| NFR3 | App size | Compressed desktop release artifact (Linux reference) | ≤ 80 MB | `flutter build linux --analyze-size` |
| NFR4 | Coverage | Line coverage on `lib/` excluding generated, `main.dart`, pure DI wiring | ≥ 80% | `flutter test --coverage` |
| NFR5 | Stability | Crash-free sessions | ≥ 99% | Crash reporter (post-F0) |
| NFR6 | Accessibility | Keyboard + screen reader labels on all P0 primary actions; 200% text scale usable | 0 blocking violations | `@flutter-a11y audit` on home + five tools |
| NFR7 | Offline | P0 tools 1,2,3,5 fully usable with no network at cold start | 100% of stated flows | Integration tests `@flutter-test integration` |
| NFR8 | Security | No secrets in bundle; no client file upload; paths with PII not logged | 0 findings | `@flutter-security audit` |
| NFR9 | Price poll | Default background interval | 10 min | Settings default + integration test |
| NFR10 | Consolidator | Report merge progress UI remains responsive for 100-file batch | No frame > 16 ms for > 1% of frames during merge | Profile on reference device |
| NFR11 | Inventory scan | Lookup after wedge scan | ≤ 200 ms p95 | Unit + integration |
| NFR12 | Document factory | Simple template batch | ≥ 50 PDFs/min reference desktop | Benchmark in F3 |

---

## 6. Observability

| Signal | Content | Never log |
|--------|---------|-----------|
| App start | version, platform, locale | User home directory full path |
| Tool run start/end | tool id, duration, success/failure enum | Full input/output paths |
| Price fetch | watch id, HTTP status class, latency ms | Full product URL if query contains tokens |
| Backup run | job id, archive size bytes, exit status | Source tree paths with client names |
| Errors | failure type, correlation id, stack (debug) | File contents, spreadsheet cells |

Analytics: minimal — optional tool usage counters local-only until release policy defined (F6).

---

## 7. Architecture decisions (ADR index)

| ADR | Topic | Status |
|-----|-------|--------|
| 20260802-001 | Technology stack lock | Accepted — `.work.flutter/decisions/20260802-001-technology-stack.md` |

**Planned ADRs (F0–F1):**

- Background price polling mechanism on Linux (timer vs workmanager desktop pattern)
- Excel read/write library boundary if `excel` fails sample corpus

---

## 8. Standards generated (P3)

Project copies in `.work.flutter/standards/` (20260802-*):

| Standard | Applicability |
|----------|---------------|
| FLUTTER_CONVENTIONS | All code |
| DIRECTORY_MAP | All code |
| FEATURE_SPEC_STANDARD | Each FT-* SPEC |
| TESTING_STANDARD | All tests |
| QUALITY_GATES | CI + verify |
| ARCHITECTURE_STANDARD | Layer enforcement |
| DATA_LAYER_STANDARD | drift + file IO |
| STATE_MANAGEMENT_STANDARD | Riverpod |
| NAVIGATION_STANDARD | go_router shell |

**Deliberately deferred to F6:** PERFORMANCE, ACCESSIBILITY, SECURITY_PRIVACY, OBSERVABILITY, RELEASE, THEMING, L10N as separate dated copies — rules are referenced via framework templates until polish milestone; NFRs and doc 02/03 capture binding numbers.

---

## 9. FLS-03 layer audit (planned structure)

Concept run `@flutter-concept-run run - FLS-03` executes after F0 scaffold. Expected violations: zero — features do not import each other's `data/` or `presentation/`; cross-tool navigation via router only.
