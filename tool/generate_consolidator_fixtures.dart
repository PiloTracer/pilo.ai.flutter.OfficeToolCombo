// Generates sample .xlsx files for manual / demo testing of FT-01.
// Usage (from repo root, after `flutter pub get`):
//   dart run tool/generate_consolidator_fixtures.dart

import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:path/path.dart' as p;

Future<void> main() async {
  final outDir = Directory(
    p.join('.work.flutter', 'fixtures', 'report_consolidator'),
  );
  outDir.createSync(recursive: true);
  for (final entity in outDir.listSync()) {
    if (entity is File &&
        (entity.path.toLowerCase().endsWith('.xlsx') ||
            entity.path.endsWith('readme_notes.txt'))) {
      entity.deleteSync();
    }
  }

  const header = <String>[
    'Date',
    'Branch',
    'SKU',
    'Product',
    'Quantity',
    'Amount',
  ];

  final branches = <String, List<List<String>>>{
    'branch_norte.xlsx': [
      header,
      <String>[
        '2026-07-01',
        'Norte',
        'SKU-100',
        'Coffee beans 1kg',
        '12',
        '48.00',
      ],
      <String>[
        '2026-07-01',
        'Norte',
        'SKU-210',
        'Paper A4 ream',
        '30',
        '90.00',
      ],
      <String>[
        '2026-07-02',
        'Norte',
        'SKU-100',
        'Coffee beans 1kg',
        '8',
        '32.00',
      ],
      <String>[
        '2026-07-02',
        'Norte',
        'SKU-330',
        'Cleaning spray',
        '15',
        '37.50',
      ],
      <String>['2026-07-03', 'Norte', 'SKU-410', 'USB cable', '20', '60.00'],
    ],
    'branch_sur.xlsx': [
      header,
      <String>[
        '2026-07-01',
        'Sur',
        'SKU-100',
        'Coffee beans 1kg',
        '6',
        '24.00',
      ],
      <String>['2026-07-01', 'Sur', 'SKU-220', 'Notebook pack', '40', '80.00'],
      <String>['2026-07-02', 'Sur', 'SKU-330', 'Cleaning spray', '10', '25.00'],
      <String>['2026-07-03', 'Sur', 'SKU-510', 'Label rolls', '5', '17.50'],
    ],
    'branch_centro.xlsx': [
      header,
      <String>[
        '2026-07-01',
        'Centro',
        'SKU-210',
        'Paper A4 ream',
        '50',
        '150.00',
      ],
      <String>[
        '2026-07-02',
        'Centro',
        'SKU-100',
        'Coffee beans 1kg',
        '4',
        '16.00',
      ],
      <String>['2026-07-03', 'Centro', 'SKU-410', 'USB cable', '12', '36.00'],
    ],
    'branch_este.xlsx': [
      header,
      <String>['2026-07-01', 'Este', 'SKU-220', 'Notebook pack', '18', '36.00'],
      <String>['2026-07-02', 'Este', 'SKU-510', 'Label rolls', '9', '31.50'],
      <String>['2026-07-03', 'Este', 'SKU-330', 'Cleaning spray', '7', '17.50'],
      <String>[
        '2026-07-03',
        'Este',
        'SKU-100',
        'Coffee beans 1kg',
        '3',
        '12.00',
      ],
    ],
    'branch_oeste.xlsx': [
      header,
      <String>['2026-07-01', 'Oeste', 'SKU-410', 'USB cable', '25', '75.00'],
      <String>[
        '2026-07-02',
        'Oeste',
        'SKU-210',
        'Paper A4 ream',
        '20',
        '60.00',
      ],
      <String>[
        '2026-07-03',
        'Oeste',
        'SKU-220',
        'Notebook pack',
        '14',
        '28.00',
      ],
    ],
    'branch_plaza.xlsx': [
      header,
      <String>[
        '2026-07-01',
        'Plaza',
        'SKU-100',
        'Coffee beans 1kg',
        '10',
        '40.00',
      ],
      <String>['2026-07-02', 'Plaza', 'SKU-510', 'Label rolls', '6', '21.00'],
    ],
    'branch_mall.xlsx': [
      header,
      <String>[
        '2026-07-01',
        'Mall',
        'SKU-330',
        'Cleaning spray',
        '22',
        '55.00',
      ],
      <String>['2026-07-02', 'Mall', 'SKU-410', 'USB cable', '11', '33.00'],
      <String>['2026-07-03', 'Mall', 'SKU-210', 'Paper A4 ream', '8', '24.00'],
    ],
    'branch_depot.xlsx': [
      header,
      <String>[
        '2026-07-01',
        'Depot',
        'SKU-220',
        'Notebook pack',
        '60',
        '120.00',
      ],
      <String>[
        '2026-07-02',
        'Depot',
        'SKU-100',
        'Coffee beans 1kg',
        '15',
        '60.00',
      ],
      <String>['2026-07-03', 'Depot', 'SKU-510', 'Label rolls', '12', '42.00'],
      <String>[
        '2026-07-03',
        'Depot',
        'SKU-330',
        'Cleaning spray',
        '18',
        '45.00',
      ],
    ],
  };

  for (final entry in branches.entries) {
    await _writeWorkbook(outDir, entry.key, entry.value);
  }

  // Valid header only — no data rows (still readable).
  await _writeWorkbook(outDir, 'header_only.xlsx', [header]);

  // Different columns — tests header-mismatch / still-mergeable path.
  await _writeWorkbook(outDir, 'header_mismatch.xlsx', [
    <String>['Fecha', 'Sucursal', 'Codigo', 'Descripcion', 'Cantidad', 'Total'],
    <String>['2026-07-01', 'Extra', 'X-1', 'Odd format row', '1', '9.99'],
  ]);

  // Empty first sheet (encode then clear conceptually: zero data cells).
  await _writeWorkbook(outDir, 'empty_sheet.xlsx', const <List<String>>[]);

  // Corrupt bytes with .xlsx extension — must appear in failure list.
  final broken = File(p.join(outDir.path, 'broken_not_excel.xlsx'));
  await broken.writeAsBytes(Uint8List.fromList(<int>[0, 1, 2, 3, 4, 5, 6, 7]));

  // Non-xlsx noise file — consolidator should ignore it.
  await File(
    p.join(outDir.path, 'readme_notes.txt'),
  ).writeAsString('Ignore me — consolidator only merges .xlsx files.\n');

  final xlsxCount = outDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.toLowerCase().endsWith('.xlsx'))
      .length;

  stdout.writeln('Wrote $xlsxCount .xlsx files to ${outDir.path}');

  final complexCount = await _generateComplexCorpus(
    p.join(outDir.path, 'complex'),
  );
  stdout.writeln(
    'Wrote $complexCount .xlsx files to ${p.join(outDir.path, 'complex')}',
  );
}

Future<int> _generateComplexCorpus(String complexPath) async {
  final complexDir = Directory(complexPath);
  complexDir.createSync(recursive: true);
  for (final entity in complexDir.listSync()) {
    if (entity is File && entity.path.toLowerCase().endsWith('.xlsx')) {
      entity.deleteSync();
    }
  }

  const complexHeader = <String>[
    'Report Date',
    'Branch Code',
    'Region',
    'Category',
    'SKU',
    'Product',
    'Qty',
    'Unit Price',
    'Discount',
    'Line Total',
  ];

  final complexBranches = <String, List<List<String>>>{
    'complex_north_hub.xlsx': [
      complexHeader,
      <String>[
        '2026-07-01',
        'N-HUB-01',
        'North',
        'Beverages',
        'SKU-100',
        'Coffee beans 1kg',
        '12',
        '4.00',
        '0.00',
        '48.00',
      ],
      <String>[
        '2026-07-01',
        'N-HUB-01',
        'North',
        'Office',
        'SKU-210',
        'Paper A4 ream',
        '30',
        '3.00',
        '5.00',
        '85.00',
      ],
      <String>[
        '2026-07-02',
        'N-HUB-01',
        'North',
        'Beverages',
        'SKU-100',
        'Coffee beans 1kg',
        '8',
        '4.00',
        '0.00',
        '32.00',
      ],
      <String>[
        '2026-07-03',
        'N-HUB-01',
        'North',
        'Electronics',
        'SKU-410',
        'USB cable',
        '20',
        '3.00',
        '2.50',
        '57.50',
      ],
    ],
    'complex_south_hub.xlsx': [
      complexHeader,
      <String>[
        '2026-07-01',
        'S-HUB-02',
        'South',
        'Beverages',
        'SKU-100',
        'Coffee beans 1kg',
        '6',
        '4.00',
        '0.00',
        '24.00',
      ],
      <String>[
        '2026-07-01',
        'S-HUB-02',
        'South',
        'Office',
        'SKU-220',
        'Notebook pack',
        '40',
        '2.00',
        '0.00',
        '80.00',
      ],
      <String>[
        '2026-07-02',
        'S-HUB-02',
        'South',
        'Cleaning',
        'SKU-330',
        'Cleaning spray',
        '10',
        '2.50',
        '1.00',
        '24.00',
      ],
      <String>[
        '2026-07-03',
        'S-HUB-02',
        'South',
        'Labels',
        'SKU-510',
        'Label rolls',
        '5',
        '3.50',
        '0.00',
        '17.50',
      ],
    ],
    'complex_central_hub.xlsx': [
      complexHeader,
      <String>[
        '2026-07-01',
        'C-HUB-03',
        'Central',
        'Office',
        'SKU-210',
        'Paper A4 ream',
        '50',
        '3.00',
        '10.00',
        '140.00',
      ],
      <String>[
        '2026-07-02',
        'C-HUB-03',
        'Central',
        'Beverages',
        'SKU-100',
        'Coffee beans 1kg',
        '4',
        '4.00',
        '0.00',
        '16.00',
      ],
      <String>[
        '2026-07-03',
        'C-HUB-03',
        'Central',
        'Electronics',
        'SKU-410',
        'USB cable',
        '12',
        '3.00',
        '0.00',
        '36.00',
      ],
    ],
    'complex_east_outlet.xlsx': [
      complexHeader,
      <String>[
        '2026-07-01',
        'E-OUT-04',
        'East',
        'Office',
        'SKU-220',
        'Notebook pack',
        '18',
        '2.00',
        '0.00',
        '36.00',
      ],
      <String>[
        '2026-07-02',
        'E-OUT-04',
        'East',
        'Labels',
        'SKU-510',
        'Label rolls',
        '9',
        '3.50',
        '0.50',
        '31.00',
      ],
      <String>[
        '2026-07-03',
        'E-OUT-04',
        'East',
        'Cleaning',
        'SKU-330',
        'Cleaning spray',
        '7',
        '2.50',
        '0.00',
        '17.50',
      ],
    ],
    'complex_west_outlet.xlsx': [
      complexHeader,
      <String>[
        '2026-07-01',
        'W-OUT-05',
        'West',
        'Electronics',
        'SKU-410',
        'USB cable',
        '25',
        '3.00',
        '5.00',
        '70.00',
      ],
      <String>[
        '2026-07-02',
        'W-OUT-05',
        'West',
        'Office',
        'SKU-210',
        'Paper A4 ream',
        '20',
        '3.00',
        '0.00',
        '60.00',
      ],
      <String>[
        '2026-07-03',
        'W-OUT-05',
        'West',
        'Office',
        'SKU-220',
        'Notebook pack',
        '14',
        '2.00',
        '2.00',
        '26.00',
      ],
    ],
    'complex_plaza_kiosk.xlsx': [
      complexHeader,
      <String>[
        '2026-07-01',
        'P-KIO-06',
        'Central',
        'Beverages',
        'SKU-100',
        'Coffee beans 1kg',
        '10',
        '4.00',
        '0.00',
        '40.00',
      ],
      <String>[
        '2026-07-02',
        'P-KIO-06',
        'Central',
        'Labels',
        'SKU-510',
        'Label rolls',
        '6',
        '3.50',
        '0.00',
        '21.00',
      ],
    ],
    'complex_depot_bulk.xlsx': [
      complexHeader,
      <String>[
        '2026-07-01',
        'D-BLK-07',
        'North',
        'Office',
        'SKU-220',
        'Notebook pack',
        '60',
        '2.00',
        '0.00',
        '120.00',
      ],
      <String>[
        '2026-07-02',
        'D-BLK-07',
        'North',
        'Beverages',
        'SKU-100',
        'Coffee beans 1kg',
        '15',
        '4.00',
        '3.00',
        '57.00',
      ],
      <String>[
        '2026-07-03',
        'D-BLK-07',
        'North',
        'Labels',
        'SKU-510',
        'Label rolls',
        '12',
        '3.50',
        '0.00',
        '42.00',
      ],
      <String>[
        '2026-07-03',
        'D-BLK-07',
        'North',
        'Cleaning',
        'SKU-330',
        'Cleaning spray',
        '18',
        '2.50',
        '4.00',
        '41.00',
      ],
    ],
    'complex_returns_adj.xlsx': [
      complexHeader,
      <String>[
        '2026-07-04',
        'R-ADJ-08',
        'South',
        'Returns',
        'SKU-900',
        'Damaged goods credit',
        '-2',
        '10.00',
        '0.00',
        '-20.00',
      ],
      <String>[
        '2026-07-04',
        'R-ADJ-08',
        'South',
        'Returns',
        'SKU-901',
        'Overstock write-off',
        '0',
        '5.00',
        '0.00',
        '0.00',
      ],
    ],
  };

  for (final entry in complexBranches.entries) {
    await _writeWorkbook(complexDir, entry.key, entry.value);
  }

  await _writeWorkbook(complexDir, 'complex_header_only.xlsx', [complexHeader]);
  await _writeWorkbook(complexDir, 'complex_mixed_types.xlsx', [
    complexHeader,
    <String>[
      '2026-07-05',
      'MIX-09',
      'East',
      'Mixed',
      'SKU-777',
      'Promo bundle',
      '3',
      '15.50',
      '1.25',
      '45.25',
    ],
  ]);

  return complexDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.toLowerCase().endsWith('.xlsx'))
      .length;
}

Future<void> _writeWorkbook(
  Directory directory,
  String fileName,
  List<List<String>> rows,
) async {
  final excel = Excel.createExcel();
  final sheet = excel.sheets.values.first;
  sheet.removeRow(0);

  for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
    final row = rows[rowIndex];
    for (var colIndex = 0; colIndex < row.length; colIndex++) {
      sheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: colIndex,
              rowIndex: rowIndex,
            ),
          )
          .value = TextCellValue(
        row[colIndex],
      );
    }
  }

  final bytes = excel.encode();
  if (bytes == null) {
    throw StateError('Failed to encode $fileName');
  }
  await File(p.join(directory.path, fileName)).writeAsBytes(bytes);
}
