---
amends: SPEC-005 (scheduled_backup)
amendment: 01
date: 2026-08-02
author: @flutter-implementation (F5), recorded by @flutter-director
re-approval: **RATIFIED by operator 2026-08-02**
---

# SPEC-005 Amendment 01 — persistence + zip engine decisions

## What changed

1. **Persistence is a SharedPreferences feature store** (single BackupJob config, last-run record, ≤10 archive entries) instead of drift `backup_jobs`/`backup_runs` tables. `lib/core/storage` is protected; no migration was added.
2. **Zip engine** is the pure-Dart `archive` package running in a worker isolate with per-file progress and sentinel-file cancellation; partial archives (`.partial`) are deleted on failure/cancel and stale partials are cleaned on next load.
3. **Offline indication** reuses the price monitor's connectivity abstraction via a feature-local provider.

## Why

- Same protected-surface rationale as SPEC-003 amendment 01.
- `archive` keeps backup fully offline and testable; the isolate + sentinel design makes interruption safe (F6/§9 partial-zip invariant) and verifiable in tests.

## Sections affected

- §7 Data contract: "drift `backup_jobs`/`backup_runs`" → SharedPreferences store.
- §13 Performance: zip IO off the UI isolate (implementation detail confirmed).

## Trace impact

- Plan F5-T2 ("drift migration and zip archive local source") is **partially superseded**: zip local source shipped; the drift migration is superseded by the SharedPreferences store.
- No change to FR6, NFR6, NFR7, NFR8; A1/A2/A5 verified by temp-dir integration + fake-clock tests.

## Re-approval

**Ratified by operator 2026-08-02** (direct reply: "I Ratify all 3 SPEC amendments").
