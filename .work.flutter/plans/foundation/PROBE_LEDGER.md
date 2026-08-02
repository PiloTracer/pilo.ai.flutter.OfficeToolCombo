# Probe ledger — OfficeToolCombo

Every question asked of the operator, the answer, and what it unblocked. Append-only.

The ledger exists so that a question is asked **once**. Re-asking something already answered wastes the operator's patience, which is a finite resource and the one that determines whether the probing gets honest answers.

Engine: `skills/probe-protocol.md`.

---

## Coverage

| Dim | Topic | ★ | Score | Confirmed means |
|-----|-------|---|-------|-----------------|
| D1 | Product intent | ★ | 2 | The problem, who has it, and what changes when it is solved |
| D2 | Users | ★ | 2 | Named personas with contexts of use |
| D3 | Platforms | ★ | 2 | Targets with minimum OS versions and form factors |
| D4 | Connectivity | ★ | 2 | Expected conditions and the offline requirement |
| D5 | Constraints | ★ | 2 | Regulatory, compliance, deadline, team, budget |
| D6 | Domain model | ★ | 2 | Entities, relationships, invariants |
| D7 | Feature inventory | ★ | 2 | Features with priorities and acceptance lines |
| D8 | NFRs | ★ | 2 | Numbers with units and reference conditions |
| D9 | Risks | | 2 | Named, with likelihood, impact and mitigation |
| D10 | Release slicing | ★ | 2 | What ships first and why |

Score: 0 unknown · 1 partial · 2 confirmed. ★ dimensions must reach 2 before the phase gate opens.

**Coverage after foundation write:** 20 / 20 confirmed = **100%** (≥ 85% gate met).

---

## Ledger

| # | Date | Dim | Question | Answer | Unblocked | Recorded in |
|---|------|-----|----------|--------|-----------|-------------|
| L1 | 2026-08-02 | D1 | In one sentence, what can someone do with this app that they cannot do today? | Run five paid office jobs (Excel merge, barcode inventory, PDF batch, price alerts, scheduled backup) from one desktop app without a terminal | P0 intent | `20260802-01-product-and-scope.md` §2 — operator stand-in 2026-08-02 |
| L2 | 2026-08-02 | D1 | What are they doing instead right now? | Manual Excel work, paper/spreadsheet inventory, mail merge, browser bookmark checks, manual/cron zip backups | P0 jobs table | `20260802-01-product-and-scope.md` §3 — operator stand-in 2026-08-02 |
| L3 | 2026-08-02 | D1 | If you could ship only one screen, which one? | Home shell listing five tools — must navigate to each entry | F0 scope | `20260802-05-feature-map-and-slices.md` §2 — operator stand-in 2026-08-02 |
| L4 | 2026-08-02 | D2 | Who opens this on a Tuesday morning? | Office coordinator, stock clerk, admin assistant, buyer, office manager — desk context | Personas | `20260802-01-product-and-scope.md` §4 — operator stand-in 2026-08-02 |
| L5 | 2026-08-02 | D2 | How will you know it worked? | Cold start ≤ 2.5 s, 80% coverage, crash-free ≥ 99%, tools complete without terminal | Success metrics | `20260802-01-product-and-scope.md` §6 — operator stand-in 2026-08-02 |
| L6 | 2026-08-02 | D3 | Which platforms ship v1? | Linux (Ubuntu 22.04+/Pop), macOS 12+, Windows 10+ desktop only; not iOS/Android/Web | P1 platforms | `20260802-02-platforms-and-constraints.md` §1–2 — operator stand-in 2026-08-02 |
| L7 | 2026-08-02 | D4 | No network at cold start? | Tools 1,2,3,5 work; price watches show offline | Connectivity | `20260802-02-platforms-and-constraints.md` §4 — operator stand-in 2026-08-02 |
| L8 | 2026-08-02 | D4 | Conflict policy for offline edits? | n/a — single device, local SoT | Doc 04 offline | `20260802-04-domain-and-data.md` §4 — operator stand-in 2026-08-02 |
| L9 | 2026-08-02 | D5 | Regulations? | No HIPAA/PCI; client files stay local; no path PII in logs | Compliance | `20260802-02-platforms-and-constraints.md` §7 — operator stand-in 2026-08-02 |
| L10 | 2026-08-02 | D5 | Locales at launch? | es + en; RTL not required | l10n | `20260802-02-platforms-and-constraints.md` §5 — operator stand-in 2026-08-02 |
| L11 | 2026-08-02 | D6 | Core nouns? | WorkbookBatch, InventoryItem, PriceWatch, DocumentJob, BackupJob (+ supporting entities) | Domain model | `20260802-04-domain-and-data.md` §1 — operator stand-in 2026-08-02 |
| L12 | 2026-08-02 | D6 | Where does data live? | Local filesystem + drift DB; never uploaded | SoT | `20260802-04-domain-and-data.md` §4 — operator stand-in 2026-08-02 |
| L13 | 2026-08-02 | D7 | P0 features? | Five tools + home shell; all P0 | Feature inventory | `20260802-05-feature-map-and-slices.md` §1 — operator stand-in 2026-08-02 |
| L14 | 2026-08-02 | D7 | Example acceptance line? | Consolidator: folder of xlsx → one clean xlsx + failed file list | Testability | `20260802-05-feature-map-and-slices.md` FT-01 — operator stand-in 2026-08-02 |
| L15 | 2026-08-02 | D8 | Cold start budget? | ≤ 2500 ms reference Linux desktop | NFR1 | `20260802-03-architecture-and-nfrs.md` §5 — operator stand-in 2026-08-02 |
| L16 | 2026-08-02 | D8 | Coverage floor? | ≥ 80% line coverage | NFR4 | `20260802-03-architecture-and-nfrs.md` §5 — `.work.flutter/STACK.md` |
| L17 | 2026-08-02 | D8 | Install size? | ≤ 80 MB compressed desktop | NFR3 | `20260802-03-architecture-and-nfrs.md` §5 — operator stand-in 2026-08-02 |
| L18 | 2026-08-02 | D9 | Top dependency worry? | `excel` package stale (last publish 2024-08-20) | Risk register | `RISK_REGISTRY.md` RSK-001 — `.work.flutter/STACK.md` |
| L19 | 2026-08-02 | D9 | Platform worry? | Desktop notification parity for price alerts | Risk register | `RISK_REGISTRY.md` RSK-002 — operator stand-in 2026-08-02 |
| L20 | 2026-08-02 | D10 | First end-to-end? | F0 shell + DI + router + theme + db bootstrap | Milestone order | `20260802-05-feature-map-and-slices.md` §2 — operator stand-in 2026-08-02 |
| L21 | 2026-08-02 | D10 | Feature order? | F0 → F1 consolidator → F2 inventory → F3 docs → F4 price → F5 backup → F6 polish | Slicing | `20260802-05-feature-map-and-slices.md` §2–3 — operator stand-in 2026-08-02 |

---

## Challenge pass

| # | Claim | Challenge | Outcome |
|---|-------|-----------|---------|
| C1 | Riverpod + drift is appropriate for five independent tools | Could each tool be a separate process? | Rejected — single shell UX is the product; shared settings and one install ≤ 80 MB — operator stand-in 2026-08-02 |
| C2 | `excel` package sufficient for consolidator | Last publish 2024-08-20 | Accepted with watch — F1 spike + fallback read path documented in RSK-001 — `.work.flutter/STACK.md` |
| C3 | Price monitor needs network but must not block app | Cold start offline behaviour | Confirmed — other tools work; watches show offline — `20260802-02-platforms-and-constraints.md` §4 |

---

## Deferred

| # | Question | Why deferred | Blocks from |
|---|----------|--------------|-------------|
| Df1 | Maximum xlsx folder size for consolidator | Needs sample corpus in F1 | F1 performance testing only — UNK-001 |
| Df2 | Linux notification daemon edge cases | Platform spike in F4 | F4 only — UNK-002 |
