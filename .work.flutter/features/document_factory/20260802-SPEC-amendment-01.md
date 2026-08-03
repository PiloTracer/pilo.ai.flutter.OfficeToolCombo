---
amends: SPEC-003 (document_factory)
amendment: 01
date: 2026-08-02
author: @flutter-implementation (F3), recorded by @flutter-director
re-approval: **RATIFIED by operator 2026-08-02**
---

# SPEC-003 Amendment 01 — template format + persistence decisions

## What changed

1. **Template format fixed to HTML (`.html`/`.htm`)** with `{{Placeholder}}` tokens. Supported subset rendered by `package:pdf`: h1–h3, p, b/strong, i/em, br, ul/li, `<img src>` (file path relative to the template, or absolute) — user logos/static content render into output PDFs (A10 satisfied). `.docx` is deferred to a follow-up milestone.
2. **Persistence is SharedPreferences feature stores** (mapping per template path, last job record) instead of drift tables. No `document_templates`/`document_jobs` drift migration was added; `lib/core/storage` is a protected surface and the F3–F5 features standardised on SharedPreferences stores.
3. **F3-T6 journey coverage** is implemented as repository-level temp-dir tests (A1/A2/A3 equivalents) rather than an `integration_test/` device journey.

## Why

- SPEC §2 explicitly leaves "exact supported formats fixed at implementation". HTML is user-owned, offline, needs no external converter (LibreOffice), and satisfies the logo requirement without app-side assets.
- Drift schema changes are protected; a SharedPreferences store delivers the same v1 behaviour (mapping restore, interrupted-job detection) without a migration.
- File pickers are platform channels; the batch journey is fully covered below the channel boundary.

## Sections affected

- §2 In scope: "PDF or Word .docx" → HTML v1 (docx follow-up).
- §7 Data contract: DocumentTemplate/DocumentJob "drift metadata" → SharedPreferences feature store.
- §15 A1–A3, A10: unchanged semantics; A3 verified via fresh store instance.

## Trace impact

- Plan F3-T2 ("drift migration for document tables") is **superseded** — no migration exists or is needed for the shipped persistence model.
- No change to FR4, NFR7, NFR12 (benchmark 22,813 PDFs/min ≥ 50/min PASS).

## Re-approval

**Ratified by operator 2026-08-02** (direct reply: "I Ratify all 3 SPEC amendments").
