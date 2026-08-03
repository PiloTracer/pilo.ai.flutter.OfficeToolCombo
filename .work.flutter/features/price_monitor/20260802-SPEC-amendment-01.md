---
amends: SPEC-004 (price_monitor)
amendment: 01
date: 2026-08-02
author: @flutter-implementation (F4), recorded by @flutter-director
re-approval: **RATIFIED by operator 2026-08-02**
---

# SPEC-004 Amendment 01 — persistence + connectivity + notification channel decisions

## What changed

1. **Persistence is a SharedPreferences feature store** (watches, latest samples, poll minutes) instead of drift `price_watches`/`price_samples` tables. `lib/core/storage` is protected; no migration was added.
2. **Connectivity probing** is a feature-local `ConnectivityService` (DNS lookup with timeout) instead of a connectivity plugin — no new platform channels.
3. **OS notification channels**: Linux `notify-send`, macOS `osascript`, Windows unsupported → in-app banner (the SPEC's mandatory R10/A7 fallback path).

## Why

- Same protected-surface rationale as SPEC-003 amendment 01.
- A DNS probe avoids adding `connectivity_plus` (desktop support varies) while keeping the offline behaviour testable via injection.
- SPEC §9/§15 already sanctions the banner as the Linux acceptance path until UNK-002 is resolved.

## Sections affected

- §7 Data contract: "drift `price_watches`/`price_samples`" → SharedPreferences store.
- §3/§11 Permissions: connectivity via probe; notification channel per platform as above.
- §15 A6/A12: remain manual (macOS/Windows pass, Linux DE matrix — UNK-002 open).

## Trace impact

- Plan F4-T2 ("drift migration and dio remote source") is **partially superseded**: dio remote source shipped; the drift migration is superseded by the SharedPreferences store.
- No change to FR5, NFR7, NFR9 (10-min default poll, fake-clock verified).

## Re-approval

**Ratified by operator 2026-08-02** (direct reply: "I Ratify all 3 SPEC amendments").
