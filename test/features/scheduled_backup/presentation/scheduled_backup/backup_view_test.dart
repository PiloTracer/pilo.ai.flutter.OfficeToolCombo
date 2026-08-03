import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/core/result/result.dart';
import 'package:office_tool_combo/core/theme/app_theme.dart';
import 'package:office_tool_combo/features/price_monitor/data/services/connectivity_service.dart';
import 'package:office_tool_combo/features/scheduled_backup/data/repositories/backup_repository_impl.dart';
import 'package:office_tool_combo/features/scheduled_backup/data/sources/backup_store.dart';
import 'package:office_tool_combo/features/scheduled_backup/domain/entities/backup_job.dart';
import 'package:office_tool_combo/features/scheduled_backup/domain/entities/backup_run.dart';
import 'package:office_tool_combo/features/scheduled_backup/domain/repositories/backup_repository.dart';
import 'package:office_tool_combo/features/scheduled_backup/presentation/scheduled_backup/backup_providers.dart';
import 'package:office_tool_combo/features/scheduled_backup/presentation/scheduled_backup/backup_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/l10n_test_harness.dart';

class FakeConnectivityService implements ConnectivityService {
  var online = true;

  @override
  Future<bool> isOnline() async => online;
}

/// Repository whose run blocks until the test releases it.
class BlockingBackupRepository implements BackupRepository {
  final completer = Completer<Result<BackupRunRecord>>();
  BackupJob job = const BackupJob(
    sourceFolder: '/src',
    destinationFolder: '/dst',
  );

  @override
  bool get isRunInProgress => true;

  @override
  Future<Result<BackupJob>> loadJob() async => Success<BackupJob>(job);

  @override
  Future<Result<void>> saveJob(BackupJob job) async {
    this.job = job;
    return const Success<void>(null);
  }

  @override
  Future<BackupRunRecord?> readLastRun() async => null;

  @override
  Future<List<BackupArchiveEntry>> readArchives() async =>
      const <BackupArchiveEntry>[];

  @override
  Future<Result<String?>> pickFolder({required String dialogTitle}) async =>
      const Success<String?>(null);

  @override
  Future<Result<BackupRunRecord>> runBackup({
    required BackupJob job,
    required BackupTrigger trigger,
    void Function(BackupRunProgress progress)? onProgress,
  }) => completer.future;

  @override
  Future<void> cancelActiveRun() async {}

  @override
  Future<void> cleanupStalePartials(String destinationPath) async {}

  @override
  Future<Result<void>> revealArchive(String path) async =>
      const Success<void>(null);
}

void main() {
  late InMemoryBackupStore store;
  late FakeConnectivityService connectivity;
  late Directory temp;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    store = InMemoryBackupStore();
    connectivity = FakeConnectivityService();
    temp = Directory.systemTemp.createTempSync('backup_view_test');
  });

  tearDown(() {
    if (temp.existsSync()) {
      temp.deleteSync(recursive: true);
    }
  });

  /// Pumps the view with in-memory fakes. The returned container must be
  /// disposed at the end of the test body — teardown disposal runs after
  /// flutter_test's pending-timer check, too late for the scheduler's
  /// periodic timer.
  Future<ProviderContainer> pumpView(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    BackupRepository? repository,
  }) async {
    tester.view.physicalSize = const Size(1400, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        backupStoreProvider.overrideWithValue(store),
        backupRepositoryProvider.overrideWithValue(
          repository ?? BackupRepositoryImpl(store: store),
        ),
        backupConnectivityServiceProvider.overrideWithValue(connectivity),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: buildL10nTestApp(
          locale: locale,
          theme: AppTheme.dark(),
          home: const BackupView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  BackupArchiveEntry archive(int index) {
    final day = (index + 1).toString().padLeft(2, '0');
    return BackupArchiveEntry(
      name: 'OfficeToolCombo-backup-2026-08-$day.zip',
      path: '/backups/OfficeToolCombo-backup-2026-08-$day.zip',
      bytes: 1024 * (index + 1),
      finishedAt: DateTime.utc(2026, 8, index + 1, 2),
    );
  }

  testWidgets('empty state: placeholders, no backups yet, disabled action', (
    tester,
  ) async {
    final container = await pumpView(tester);

    expect(find.text('No source folder selected'), findsOneWidget);
    expect(find.text('No destination folder selected'), findsOneWidget);
    expect(find.text('No backups yet'), findsOneWidget);
    expect(find.text('No archives yet'), findsOneWidget);
    expect(find.text('Run a backup to see archives here.'), findsOneWidget);

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Back up now'),
    );
    expect(button.onPressed, isNull);
    container.dispose();
  });

  testWidgets('A9: "Back up now" is a full-width primary action >= 48px', (
    tester,
  ) async {
    final container = await pumpView(tester);

    final finder = find.widgetWithText(FilledButton, 'Back up now');
    expect(finder, findsOneWidget);
    expect(tester.getSize(finder).height, greaterThanOrEqualTo(48));
    expect(tester.getSize(finder).width, greaterThan(800));
    container.dispose();
  });

  testWidgets('A3: unwritable destination fails with the SPEC message', (
    tester,
  ) async {
    store.job = BackupJob(
      sourceFolder: temp.path,
      destinationFolder: '${temp.path}/no/such/folder',
    );
    final container = await pumpView(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Back up now'));
    await tester.pumpAndSettle();

    expect(find.text('Last backup: failed'), findsOneWidget);
    expect(
      find.text(
        'Cannot write to the destination folder. Choose a different folder or check permissions.',
      ),
      findsWidgets,
    );
    // R7 — no archive entry added.
    expect(await store.readArchives(), isEmpty);
    expect(find.text('No archives yet'), findsOneWidget);
    container.dispose();
  });

  testWidgets('A4: missing source shows the SPEC message', (tester) async {
    store.job = BackupJob(
      sourceFolder: '${temp.path}/gone',
      destinationFolder: temp.path,
    );
    final container = await pumpView(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Back up now'));
    await tester.pumpAndSettle();

    expect(find.text('Last backup: failed'), findsOneWidget);
    expect(
      find.text('Source folder not found. Choose the folder again.'),
      findsWidgets,
    );
    expect(await store.readArchives(), isEmpty);
    container.dispose();
  });

  testWidgets('A4 (es): failure message is localized', (tester) async {
    store.job = BackupJob(
      sourceFolder: '${temp.path}/gone',
      destinationFolder: temp.path,
    );
    final container = await pumpView(tester, locale: const Locale('es'));

    await tester.tap(find.widgetWithText(FilledButton, 'Crear copia ahora'));
    await tester.pumpAndSettle();

    expect(find.text('Última copia: fallida'), findsOneWidget);
    expect(
      find.text(
        'No se encontró la carpeta de origen. Elija la carpeta de nuevo.',
      ),
      findsWidgets,
    );
    container.dispose();
  });

  testWidgets('A6: archives list shows at most 10, newest first', (
    tester,
  ) async {
    store.job = BackupJob(
      sourceFolder: temp.path,
      destinationFolder: temp.path,
    );
    // Store order is newest-first (the repository prepends new entries).
    store.archives = List.generate(12, (i) => archive(11 - i));
    final container = await pumpView(tester);

    // 12 seeded entries, but only 10 rendered (R8 cap applied by the
    // repository — here the list is trimmed to the newest 10).
    expect(find.text('OfficeToolCombo-backup-2026-08-12.zip'), findsOneWidget);
    expect(find.text('OfficeToolCombo-backup-2026-08-03.zip'), findsOneWidget);
    expect(find.text('OfficeToolCombo-backup-2026-08-02.zip'), findsNothing);
    expect(find.text('OfficeToolCombo-backup-2026-08-01.zip'), findsNothing);

    // Newest first: the 12th-day entry sits above the 11th-day entry.
    final newest = tester.getTopLeft(
      find.text('OfficeToolCombo-backup-2026-08-12.zip'),
    );
    final older = tester.getTopLeft(
      find.text('OfficeToolCombo-backup-2026-08-11.zip'),
    );
    expect(newest.dy, lessThan(older.dy));
    container.dispose();
  });

  testWidgets('offline shows the neutral note; controls stay enabled', (
    tester,
  ) async {
    connectivity.online = false;
    store.job = BackupJob(
      sourceFolder: temp.path,
      destinationFolder: temp.path,
    );
    final container = await pumpView(tester);

    expect(
      find.text('Backups use local folders only. No internet required.'),
      findsOneWidget,
    );
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Back up now'),
    );
    expect(button.onPressed, isNotNull);
    container.dispose();
  });

  testWidgets('in-progress run disables the button and shows running copy', (
    tester,
  ) async {
    final blocking = BlockingBackupRepository();
    final container = await pumpView(tester, repository: blocking);

    await tester.tap(find.widgetWithText(FilledButton, 'Back up now'));
    await tester.pump();

    expect(find.text('Creating backup…'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Creating backup…'),
    );
    expect(button.onPressed, isNull);

    blocking.completer.complete(
      Success<BackupRunRecord>(
        BackupRunRecord(
          status: BackupRunStatus.succeeded,
          messageCode: '',
          timestamp: DateTime.now().toUtc(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Back up now'), findsOneWidget);
    container.dispose();
  });

  testWidgets('stored config populates fields and defaults', (tester) async {
    store.job = BackupJob(
      sourceFolder: '${temp.path}/documents',
      destinationFolder: '${temp.path}/backups',
      dailyRunHour: 14,
      scheduleEnabled: false,
    );
    final container = await pumpView(tester);

    expect(find.text('documents'), findsOneWidget);
    expect(find.text('backups'), findsOneWidget);
    expect(find.text('14:00'), findsOneWidget);
    final toggle = tester.widget<Switch>(find.byType(Switch));
    expect(toggle.value, isFalse);
    // Folders configured but nothing ran yet — partial state copy.
    expect(find.text('Last backup: unknown'), findsOneWidget);
    container.dispose();
  });
}
