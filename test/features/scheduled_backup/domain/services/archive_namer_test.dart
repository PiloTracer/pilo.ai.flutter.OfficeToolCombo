import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/features/scheduled_backup/domain/services/archive_namer.dart';

void main() {
  final runStart = DateTime(2026, 8, 2, 14, 30, 15);

  test('R2: base name contains the local YYYY-MM-DD of the run start', () {
    expect(
      ArchiveNamer.baseName(runStart),
      'OfficeToolCombo-backup-2026-08-02.zip',
    );
  });

  test('R2: date is zero-padded', () {
    expect(
      ArchiveNamer.baseName(DateTime(2026, 1, 5, 3, 4, 5)),
      'OfficeToolCombo-backup-2026-01-05.zip',
    );
  });

  test('same-day re-run appends -HHmmss when the base name exists', () {
    final name = ArchiveNamer.resolveName(
      runStart,
      (candidate) => candidate == 'OfficeToolCombo-backup-2026-08-02.zip',
    );
    expect(name, 'OfficeToolCombo-backup-2026-08-02-143015.zip');
  });

  test('further collisions append a counter, never an existing name', () {
    final taken = <String>{
      'OfficeToolCombo-backup-2026-08-02.zip',
      'OfficeToolCombo-backup-2026-08-02-143015.zip',
      'OfficeToolCombo-backup-2026-08-02-143015-2.zip',
    };
    final name = ArchiveNamer.resolveName(runStart, taken.contains);
    expect(name, 'OfficeToolCombo-backup-2026-08-02-143015-3.zip');
    expect(taken.contains(name), isFalse);
  });

  test('R3/A2: a prior-day archive is never overwritten by today\'s run', () {
    // The destination already holds archives from the two previous days.
    final onDisk = <String>{
      'OfficeToolCombo-backup-2026-07-31.zip',
      'OfficeToolCombo-backup-2026-08-01.zip',
    };
    final queried = <String>[];
    final name = ArchiveNamer.resolveName(runStart, (candidate) {
      queried.add(candidate);
      return onDisk.contains(candidate);
    });

    // The resolved name always embeds today's date, so yesterday's file is
    // unreachable — it is never even probed as a candidate.
    expect(ArchiveNamer.embeddedDate(name), '2026-08-02');
    expect(
      queried.every(
        (candidate) => ArchiveNamer.embeddedDate(candidate) == '2026-08-02',
      ),
      isTrue,
    );
    expect(onDisk.contains(name), isFalse);
  });

  test('embeddedDate parses pattern names and rejects foreign files', () {
    expect(
      ArchiveNamer.embeddedDate('OfficeToolCombo-backup-2026-08-02.zip'),
      '2026-08-02',
    );
    expect(
      ArchiveNamer.embeddedDate('OfficeToolCombo-backup-2026-08-02-143015.zip'),
      '2026-08-02',
    );
    expect(ArchiveNamer.embeddedDate('other-file.zip'), isNull);
  });
}
