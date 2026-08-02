# Master plan probe ledger — OfficeToolCombo

**Plan:** `20260802-full-plan.md`  
**Updated:** 2026-08-02 (Revision 2 commercial bar + bilingual)

Engine: framework `probe-protocol.md`. Operator answers from `@flutter-director` confirm 2026-08-02.

---

## Coverage map

| Dim | Topic | ★ | Status | Evidence |
|-----|-------|---|---------|----------|
| P1 | Requirement coverage | ★ | confirmed | FR1–FR10, NFR1–NFR13 mapped; `traceability-verify.sh` PASS |
| P2 | Task concreteness | ★ | confirmed | 53 tasks with file paths + verification |
| P3 | Sequencing | ★ | confirmed | F0→F1…F5→F6; excel risk early (F1); no forward deps |
| P4 | Demoability | ★ | confirmed | Each milestone exit is a person action (Rev 2 demos) |
| P5 | Estimates | | confirmed | S/M/L with basis on new commercial tasks |
| P6 | Verification | ★ | confirmed | §14 updated per milestone; NFR13 on F0/F6 |
| P7 | Risk absorption | | confirmed | RSK-001…008 still sequenced; bilingual never-cut |
| P8 | Release path | | confirmed | F6 artifacts; UNK-003 signing accepted workaround |

**Coverage:** 8/8 dimensions confirmed (100%).

## Challenge pass

| Claim | Verdict | Note |
|-------|---------|------|
| Buyer-ready five tools planned | defensible | Commercial bar in doc 01 §4b + SPECs Review |
| Hard bilingual + locale persist | defensible | FR10, NFR13, F0-T12, settings SPEC; cut list forbids en-only |
| Outside control | accepted gaps | UNK-001 folder size; UNK-002 Linux notify; UNK-003 Windows signing |

**Challenge:** defensible with carried UNK-001…003 (non-blocking for plan re-approval).

## Operator decisions recorded

1. Bilingual en/es non-negotiable for v1  
2. Locale survives cold start  
3. Full plans = deepen master plan + SPECs for FT-00…FT-06  
4. Commercial gaps beyond transcript included as must-ship v1 (not P1)
