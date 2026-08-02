# ADR-001 — Technology stack lock

**Status:** Accepted  
**Date:** 2026-08-02  
**Context:** Framework verification run for OfficeToolCombo (desktop office tools combo).

## Decision

Lock Riverpod 3 + go_router + freezed/json_serializable + dio + drift/sqlite3 3.x + mocktail.

## Consequences

- Scaffold and implementation generate Riverpod idioms only.
- SQLite native libs come from `package:sqlite3` ≥3.x, not `sqlite3_flutter_libs`.
- `excel` is accepted with a maintenance watch (last publish 2024-08-20 as of lock date).

## Alternatives considered

See `.work.flutter/STACK.md` § Rejected.
