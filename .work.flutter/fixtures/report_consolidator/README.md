# Report consolidator sample corpus (FT-01)

Folder of `.xlsx` files for **manual demo** of the Report consolidator.

**Regenerate:** from repo root, after `flutter pub get`:

```bash
dart run tool/generate_consolidator_fixtures.dart
```

## How to use in the app

1. `flutter run -d linux`
2. Open **Report consolidator**
3. Choose this folder: `.work.flutter/fixtures/report_consolidator`
4. Run merge — expect a consolidated workbook plus a failure list for bad files

## Contents

| File | Purpose |
|------|---------|
| `branch_*.xlsx` (8 files) | Valid branch sales reports — shared header `Date, Branch, SKU, Product, Quantity, Amount` |
| `header_only.xlsx` | Header row, no data |
| `header_mismatch.xlsx` | Different Spanish-style column names |
| `empty_sheet.xlsx` | Empty first sheet |
| `broken_not_excel.xlsx` | Corrupt bytes (must fail gracefully) |
| `readme_notes.txt` | Noise file — should be ignored (not `.xlsx`) |

Good files alone: **8** branch workbooks. With intentional failures: **12** `.xlsx` candidates.
