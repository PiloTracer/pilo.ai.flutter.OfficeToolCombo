---
amends: SPEC-005 (scheduled_backup)
amendment: 02
date: 2026-08-02
author: @flutter-implementation, recorded by @flutter-director
re-approval: **RATIFIED by operator 2026-08-02**
---

# SPEC-005 Amendment 02 — multiple labeled jobs, richer schedules, unified run log

## What changed

1. **Multiple backup jobs with labels** (was: exactly one job, §2 out of scope "Multiple concurrent backup jobs"). Each job: id, label (≤120 chars), source, destination, schedule, enabled. Full CRUD from the UI.
2. **Schedule kinds** (was: "Sub-daily schedules — daily hour only", §2 out of scope / ASM-005): HOURLY = every N hours, N ∈ {1,2,3,4,6,8,12} · DAILY = at hour (unchanged) · WEEKLY = weekday + hour · MONTHLY = day-of-month + hour, clamped to last day of short months.
3. **Unified run log replaces per-config last-run/archives sections**: one log across all jobs, newest first, capped 50, each entry carries the **job label**, outcome, archive name + size (success) or message code (failure), and a reveal-in-folder icon (DesktopFileReveal) on success rows.

## Locked interpretations (operator was offered correction before implementation)

- "Hourly (multiple hours)" → every N hours (interval), not multi-picked clock hours.
- Label lives in the log, **not** in archive filenames (naming unchanged: `OfficeToolCombo-backup-YYYY-MM-DD[-HHmmss].zip`).
- Migration: v1 single config becomes job #1 "Default backup"; legacy storage keys cleaned on first read.
- One run at a time globally (R5 preserved); runs only while the app process is alive; missed days not backfilled (R6 policy extended to weekly/monthly).

## Sections affected

- §2 Scope: multi-job and sub-daily schedules move from out-of-scope to in-scope.
- §5/§6 Screens and states: jobs list + job editor dialog + unified run log replace single-config sections.
- §7 Data contract: BackupJob gains id/label/schedule; run history becomes BackupRunLogEntry list (cap 50).
- ASM-005 superseded for hourly; weekly/monthly added.

## Trace impact

- Plan F5 tasks remain valid; schedule/log UI work extends F5-T3/F5-T6.
- No FR/NFR changes; R5/R6/R7 semantics preserved and extended per job.

## Re-approval

**Ratified by operator 2026-08-02** (direct reply: "YES I RATIFY SPEC-005 amendment-02").
