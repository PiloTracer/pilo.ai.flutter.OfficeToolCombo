# 04 — Domain and data

**Status:** Complete   **Phase:** P4   **Updated:** 2026-08-02

---

## 1. Entities

| Entity | Key attributes | Invariants | Source of truth | Lifetime |
|--------|----------------|------------|-----------------|----------|
| **WorkbookBatch** | id, sourceFolderUri, outputPath, status, startedAt, finishedAt | Output path must be writable before run starts; status transitions monotonic | Local run record (drift) + output file on disk | Per consolidator run |
| **SpreadsheetFile** | path (basename in UI), parseStatus, errorMessage? | Listed relative to batch; failed files do not abort whole batch unless operator chooses | In-memory during run; failures persisted on batch | Per file in batch |
| **InventoryItem** | sku, barcode, name, quantityOnHand, updatedAt | Barcode unique; quantity ≥ 0 | drift `inventory_items` | Until deleted |
| **ScanEvent** | id, barcode, itemId?, scannedAt, delta | Append-only audit; delta applied atomically with item update | drift `scan_events` | Retained per retention policy (default 90 days) |
| **DocumentJob** | id, templatePath, dataSheetPath, outputDir, status, progress | Template columns must map to data sheet headers | drift + output PDFs on disk | Per factory run |
| **DocumentTemplate** | id, name, filePath, fieldMapping | Mapping keys stable for reuse | drift metadata; template file on disk | Until operator removes |
| **PriceWatch** | id, label, url, threshold, currency, direction, enabled | URL valid http(s); threshold > 0 as Decimal | drift `price_watches` | Until deleted |
| **PriceSample** | id, watchId, price, fetchedAt, rawStatus | Latest sample per watch overwrites display; history optional | drift `price_samples` | Rolling window (default 30 days) |
| **BackupJob** | id, sourceFolderUri, destinationFolderUri, scheduleCron, enabled | Source must exist at run time; destination writable | drift `backup_jobs` | Until deleted |
| **BackupRun** | id, jobId, archivePath, startedAt, finishedAt, status, bytesWritten | Archive name includes ISO date | drift + zip on disk | Per scheduled/manual run |
| **AppSettings** | locale, themeMode, pricePollMinutes, scanRetentionDays, logLevel | Single row id=1 | drift `app_settings` + shared_preferences for bootstrap scalars | App lifetime |

---

## 2. Relationships

```
WorkbookBatch 1 — * SpreadsheetFile (embedded list during run; failures persisted on batch)

InventoryItem 1 — * ScanEvent

DocumentTemplate 1 — * DocumentJob

PriceWatch 1 — * PriceSample (latest displayed; history retained)

BackupJob 1 — * BackupRun

AppSettings 1 — 1 (singleton configuration)
```

No cross-feature foreign keys except through optional shared `AppSettings`. Tools do not read each other's tables directly; shared lookups go through repository interfaces if needed later.

---

## 3. Data flow per surface

| Surface | Reads from | Writes to | Cached | Staleness tolerance |
|---------|------------|-----------|--------|---------------------|
| Home shell | AppSettings | — | Settings in memory | Until settings change |
| Report consolidator | Folder picker paths, xlsx files | Output xlsx, batch record | In-run file list | n/a — batch job |
| Barcode inventory | drift inventory + scan stream | drift items/events | Full table in memory for active session | Real-time on scan |
| Document factory | Template file, data xlsx, drift job | PDFs, job progress | Job state | Progress ≤ 1 s behind |
| Price monitor | drift watches, dio fetch | drift samples, notifications | Latest price per watch | Default 10 min between polls |
| Scheduled backup | drift jobs, filesystem | zip archives, run records | Next-run schedule | Schedule drift ≤ 1 min |
| Settings | AppSettings repo | AppSettings repo | Immediate | None |

---

## 4. Offline and sync

| Entity | Cached | Writable offline | Conflict policy | Eviction |
|--------|--------|------------------|-----------------|----------|
| WorkbookBatch / SpreadsheetFile | n/a | Yes — local files only | n/a | Batch records pruned after 30 days (configurable) |
| InventoryItem / ScanEvent | Yes (drift) | Yes | n/a single device | Scan events > retention days |
| DocumentJob | Yes | Yes | n/a | Completed jobs > 30 days metadata only |
| PriceWatch / PriceSample | Yes | Watches editable; fetch requires network | n/a | Samples > 30 days |
| BackupJob / BackupRun | Yes | Yes — local zip | n/a | Runs > 90 days metadata |
| AppSettings | Yes | Yes | n/a | Never auto-evict |

**Offline model summary:** Source of truth is **local** (drift DB + user-selected filesystem paths). No cloud sync. Price monitor shows offline badge and skips fetch; other tools unaffected at cold start without network.

---

## 5. Data classification

| Data | Class | Storage | Retention | Never logged |
|------|-------|---------|-----------|--------------|
| Client xlsx/pdf paths | sensitive internal | User disk | User-controlled | Full paths |
| Inventory SKUs/names | internal | drift | Until deleted | — |
| Barcodes | internal | drift | Until deleted | — |
| Price URLs | internal | drift | Until deleted | Query strings with tokens |
| Backup archives | sensitive internal | User disk | User-controlled | Full paths |
| App logs | internal | Local log file | 7 days rolling | Paths, cell values |
| Credentials | n/a v1 | — | — | Always |

---

## 6. Local store schema and migration policy

| Aspect | Policy |
|--------|--------|
| Engine | drift on sqlite3 (see STACK.md K6) |
| Schema versioning | Incremental migrations `001_initial`, `002_…` — forward-only |
| Testing | Migrate from every shipped version; run twice for idempotence |
| Destructive changes | Require explicit human approval |
| Bootstrap | F0 creates empty schema + AppSettings default row |
| File assets | Templates and outputs remain files; DB stores paths as strings only |

**Initial tables (F0–F2):** `app_settings`, `inventory_items`, `scan_events`. **F3+:** `document_jobs`, `document_templates`. **F4:** `price_watches`, `price_samples`. **F5:** `backup_jobs`, `backup_runs`. **F1:** `workbook_batches` optional metadata table.
