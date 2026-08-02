---
status: locked
locked-by: autonomous-operator-stand-in (framework test-run)
locked-date: 2026-08-02
---

# Technology stack — OfficeToolCombo

**Status: Locked**
**Locked:** 2026-08-02
**Locked by:** autonomous-operator-stand-in (framework verification run)
**Changing this** requires an ADR in `.work.flutter/decisions/` + `@flutter-plan-master revise`.

Versions and licences verified on pub.dev on 2026-08-02 (live API + package page License field).

## Decisions

| Dim | Choice | Package | Version (seen) | License | Rationale |
|-----|--------|---------|----------------|---------|-----------|
| K1 ★ State | Riverpod 3 | `flutter_riverpod` | 3.4.2 | MIT | Async tools (price monitor, backups) + built-in DI; single system |
| K2 ★ Navigation | go_router | `go_router` | 17.3.0 | BSD-3-Clause | Shell with five tool routes; Flutter-team maintained |
| K3 ★ DI | Riverpod | (same as K1) | 3.4.2 | MIT | No second DI mechanism |
| K4 ★ Models | freezed + json_serializable | `freezed` / `json_serializable` | 3.2.5 / 6.14.1 | MIT / BSD-3 | Sealed failure unions; immutable domain rows |
| K5 HTTP | dio | `dio` | 5.11.0 | MIT | Price monitor needs timeouts, cancellation, retries |
| K6 ★ Local store | drift + sqlite3 | `drift` / `sqlite3` | 2.34.3 / 3.5.0 | MIT / MIT | Relational inventory, watches, backup jobs. **Not** `sqlite3_flutter_libs` (EOL — use sqlite3 ≥3.x) |
| K7 Test doubles | mocktail | `mocktail` | 1.0.5 | MIT | No codegen for doubles |

**Idiom guide:** `stacks/riverpod.md`

## Supporting packages

| Package | Version (seen) | Licence | Purpose | Platforms | Replacement if abandoned |
|---------|----------------|---------|---------|-----------|--------------------------|
| `riverpod_annotation` / `riverpod_generator` | 4.0.6 / 4.0.8 | MIT | Codegen providers | all | hand-written providers |
| `build_runner` | 2.16.0 | BSD-3 | Codegen driver | all | — |
| `path_provider` | 2.1.6 | BSD-3 | App data dirs | desktop | `path` + XDG dirs |
| `file_picker` | 11.0.3 | MIT | Folder/file pickers | desktop | platform file dialogs |
| `excel` | 4.0.6 | MIT | Read/write xlsx | all | **Stale publish (2024-08-20)** — watch; fallback `spreadsheet_decoder` for read |
| `pdf` | 3.13.0 | MIT | PDF generation | all | `syncfusion_flutter_pdf` refused (commercial) |
| `archive` | 4.0.9 | MIT | Zip for backups | all | `native` zip CLI |
| `flutter_local_notifications` | 22.2.0 | BSD-3 | Price/backup alerts | desktop | OS-specific notify |
| `shared_preferences` | 2.5.5 | BSD-3 | Scalar prefs (schedule hour) | all | drift settings table |
| `decimal` | 3.2.6 | Apache-2.0 | Money/prices — never `double` | all | — |
| `path` | 1.9.1 | BSD-3 | Path join | all | — |
| `intl` | 0.20.2+ | BSD-3 | Dates in archive names | all | — |
| `equatable` | 2.1.0 | MIT | Value equality where freezed unused | all | freezed |

## Exceptions

None — one library per dimension.

## Rejected

| Considered | Rejected because |
|------------|------------------|
| Bloc | Extra ceremony for five mostly-independent tools; team stand-in has no Bloc inventory |
| Provider + ChangeNotifier | Weaker async story for background price polls |
| auto_route | Codegen overhead not justified for five static routes |
| get_it | Redundant with Riverpod DI |
| sqflite | Lower typed-query / migration story than drift |
| `sqlite3_flutter_libs` | **EOL** — pub.dev: use `sqlite3` 3.x |
| hive / isar | Abandoned / Play 16KB issues (catalog exclusions) |
| Syncfusion PDF | Commercial — license policy refuse |

## Constraints that drove the choice

| Constraint | Source |
|------------|--------|
| Desktop-first (Linux/macOS/Windows), no mobile v1 | product intent / ideas transcript |
| Local-first, mostly offline; network only for price monitor | ideas transcript app 4 |
| Commercial-use OSS only | PACKAGE_LICENSE_STANDARD |
| Team: solo / agent-assisted, accepts codegen | autonomous stand-in |

## Probe ledger

| Dim | Status | Evidence |
|-----|--------|----------|
| K1 | confirmed | stand-in: Riverpod for async + DI |
| K2 | confirmed | five-tool shell, go_router |
| K3 | confirmed | follows K1 |
| K4 | confirmed | freezed unions for tool failures |
| K5 | confirmed | dio for price fetch |
| K6 | confirmed | drift+sqlite3; expensive reverse confirmed |
| K7 | confirmed | mocktail |

**Challenge:** defensible — K1/K6 expensive-to-reverse confirmed by stand-in. Gap: `excel` publish age flagged.

## Change log

| Date | Dimension | From → To | ADR | Migration |
|------|-----------|-----------|-----|-----------|
| 2026-08-02 | all | unlocked → locked | 20260802-001-technology-stack.md | n/a |
