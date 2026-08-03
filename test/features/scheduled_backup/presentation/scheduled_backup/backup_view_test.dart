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

/// Repository fake whose run blocks until the test releases it and which
/// records reveal calls through the reveal seam.
class FakeBackupRepository implements BackupRepository {
  FakeBackupRepository({
    this.jobs = const <BackupJob>[],
    this.runLog = const <BackupRunLogEntry>[],
  });

  final completer = Completer<Result<BackupRunLogEntry>>();
  final revealedPaths = <String>[];
  List<BackupJob> jobs;
  List<BackupRunLogEntry> runLog;
  var blockRuns = false;

  @override
  bool get isRunInProgress => blockRuns;

  @override
  Future<Result<List<BackupJob>>> loadJobs() async =>
      Success<List<BackupJob>>(jobs);

  @override
  Future<Result<void>> saveJob(BackupJob job) async {
    final index = jobs.indexWhere((existing) => existing.id == job.id);
    if (index >= 0) {
      jobs[index] = job;
    } else {
      jobs = List<BackupJob>.from(jobs)..add(job);
    }
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> deleteJob(String jobId) async {
    jobs = jobs.where((job) => job.id != jobId).toList();
    return const Success<void>(null);
  }

  @override
  Future<List<BackupRunLogEntry>> readRunLog() async => runLog;

  @override
  Future<DateTime?> lastRunAt(String jobId) async => null;

  @override
  Future<Result<String?>> pickFolder({required String dialogTitle}) async =>
      const Success<String?>(null);

  @override
  Future<Result<BackupRunLogEntry>> runBackup({
    required BackupJob job,
    required BackupTrigger trigger,
    void Function(BackupRunProgress progress)? onProgress,
  }) {
    if (!blockRuns) {
      return Future<Result<BackupRunLogEntry>>.value(
        Success<BackupRunLogEntry>(
          BackupRunLogEntry(
            jobId: job.id,
            jobLabel: job.label,
            finishedAt: DateTime.now().toUtc(),
            status: BackupRunStatus.succeeded,
          ),
        ),
      );
    }
    return completer.future;
  }

  @override
  Future<void> cancelActiveRun() async {}

  @override
  Future<void> cleanupStalePartials(String destinationPath) async {}

  @override
  Future<Result<void>> revealArchive(String path) async {
    revealedPaths.add(path);
    return const Success<void>(null);
  }
}

void main() {
  late InMemoryBackupStore store;
  late FakeConnectivityService connectivity;
  late Directory temp;

  const docsJob = BackupJob(
    id: 'job-a',
    label: 'Docs backup',
    sourceFolder: '/src',
    destinationFolder: '/dst',
    schedule: BackupSchedule.weekly(weekday: DateTime.monday, hour: 2),
    // Scheduling is off unless a test exercises it — the scheduler must not
    // fire background runs into the fake/real repositories mid-test.
    enabled: false,
  );

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

  BackupJob tempJob({String id = 'job-a', String label = 'Docs backup'}) =>
      BackupJob(
        id: id,
        label: label,
        sourceFolder: temp.path,
        destinationFolder: temp.path,
        enabled: false,
      );

  testWidgets('empty state: no jobs, empty run log, add action', (
    tester,
  ) async {
    final container = await pumpView(tester);

    expect(find.text('No backup jobs yet'), findsOneWidget);
    expect(find.text('Add a backup job to protect a folder.'), findsOneWidget);
    expect(find.text('No runs yet'), findsOneWidget);
    expect(find.text('Run a backup to see history here.'), findsOneWidget);
    expect(find.text('Add backup'), findsOneWidget);
    container.dispose();
  });

  testWidgets('jobs list renders labels and schedule summaries (en)', (
    tester,
  ) async {
    store.jobs = const [
      BackupJob(
        id: 'job-1',
        label: 'Hourly sync',
        sourceFolder: '/a',
        destinationFolder: '/b',
        schedule: BackupSchedule.hourly(everyHours: 4),
        enabled: false,
      ),
      docsJob,
      BackupJob(
        id: 'job-3',
        label: 'Month-end close',
        sourceFolder: '/c',
        destinationFolder: '/d',
        schedule: BackupSchedule.monthly(dayOfMonth: 31, hour: 23),
        enabled: false,
      ),
    ];
    final container = await pumpView(tester);

    expect(find.text('Hourly sync'), findsOneWidget);
    expect(find.text('Every 4 hours'), findsOneWidget);
    expect(find.text('Docs backup'), findsOneWidget);
    expect(find.text('Weekly on Monday at 02:00'), findsOneWidget);
    expect(find.text('Month-end close'), findsOneWidget);
    expect(find.text('Monthly on day 31 at 23:00'), findsOneWidget);
    container.dispose();
  });

  testWidgets('jobs list renders schedule summaries in Spanish', (
    tester,
  ) async {
    store.jobs = const [
      BackupJob(
        id: 'job-1',
        label: 'Sincronización',
        sourceFolder: '/a',
        destinationFolder: '/b',
        schedule: BackupSchedule.hourly(everyHours: 4),
        enabled: false,
      ),
      docsJob,
    ];
    final container = await pumpView(tester, locale: const Locale('es'));

    expect(find.text('Cada 4 horas'), findsOneWidget);
    expect(find.text('Semanalmente el lunes a las 02:00'), findsOneWidget);
    expect(find.text('Añadir copia de seguridad'), findsOneWidget);
    container.dispose();
  });

  testWidgets('add-backup dialog creates a new job', (tester) async {
    final container = await pumpView(tester);

    await tester.tap(find.text('Add backup'));
    await tester.pumpAndSettle();
    expect(find.text('New backup job'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Photos archive');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Photos archive'), findsOneWidget);
    expect(find.text('Daily at 02:00'), findsOneWidget);
    expect(store.jobs.single.label, 'Photos archive');
    container.dispose();
  });

  testWidgets('job label validation blocks saving an empty label', (
    tester,
  ) async {
    final container = await pumpView(tester);

    await tester.tap(find.text('Add backup'));
    await tester.pumpAndSettle();

    final save = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Save'),
    );
    expect(save.onPressed, isNull);
    expect(find.text('Enter a label (up to 120 characters).'), findsWidgets);
    container.dispose();
  });

  testWidgets('delete asks for confirmation and removes the job', (
    tester,
  ) async {
    store.jobs = const [docsJob];
    final container = await pumpView(tester);

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete backup job?'), findsOneWidget);
    expect(
      find.text('Delete “Docs backup”? Existing archives are kept.'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Docs backup'), findsNothing);
    expect(find.text('No backup jobs yet'), findsOneWidget);
    expect(store.jobs, isEmpty);
    container.dispose();
  });

  testWidgets('cancel on the delete dialog keeps the job', (tester) async {
    store.jobs = const [docsJob];
    final container = await pumpView(tester);

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Docs backup'), findsOneWidget);
    expect(store.jobs, hasLength(1));
    container.dispose();
  });

  testWidgets('run log rows show the label; reveal calls the reveal seam', (
    tester,
  ) async {
    final fake = FakeBackupRepository(
      jobs: const [docsJob],
      runLog: <BackupRunLogEntry>[
        BackupRunLogEntry(
          jobId: 'job-a',
          jobLabel: 'Docs backup',
          finishedAt: DateTime.utc(2026, 8, 2, 14, 3),
          status: BackupRunStatus.succeeded,
          archiveName: 'OfficeToolCombo-backup-2026-08-02.zip',
          archiveBytes: 2048,
          archivePath: '/dst/OfficeToolCombo-backup-2026-08-02.zip',
        ),
      ],
    );
    final container = await pumpView(tester, repository: fake);

    // Label and archive basename are visible; the full path never is (NFR8).
    expect(find.text('Docs backup'), findsWidgets);
    expect(
      find.textContaining('OfficeToolCombo-backup-2026-08-02.zip'),
      findsOneWidget,
    );
    expect(find.textContaining('/dst/'), findsNothing);

    await tester.tap(find.byTooltip('Show in file manager'));
    await tester.pumpAndSettle();
    expect(fake.revealedPaths, ['/dst/OfficeToolCombo-backup-2026-08-02.zip']);
    container.dispose();
  });

  testWidgets('failed run log entry shows the localized failure message', (
    tester,
  ) async {
    final fake = FakeBackupRepository(
      jobs: const [docsJob],
      runLog: <BackupRunLogEntry>[
        BackupRunLogEntry(
          jobId: 'job-a',
          jobLabel: 'Docs backup',
          finishedAt: DateTime.utc(2026, 8, 2, 14, 3),
          status: BackupRunStatus.failed,
          messageCode: 'backup.source_missing',
        ),
      ],
    );
    final container = await pumpView(tester, repository: fake);

    expect(find.textContaining('Failed'), findsOneWidget);
    expect(
      find.text('Source folder not found. Choose the folder again.'),
      findsOneWidget,
    );
    // Failed rows have no reveal button.
    expect(find.byTooltip('Show in file manager'), findsNothing);
    container.dispose();
  });

  testWidgets('A9: "Add backup" is a full-width primary action >= 48px', (
    tester,
  ) async {
    final container = await pumpView(tester);

    final finder = find.widgetWithText(FilledButton, 'Add backup');
    expect(finder, findsOneWidget);
    expect(tester.getSize(finder).height, greaterThanOrEqualTo(48));
    expect(tester.getSize(finder).width, greaterThan(800));
    container.dispose();
  });

  testWidgets('A3: unwritable destination surfaces the SPEC message per job', (
    tester,
  ) async {
    store.jobs = [
      BackupJob(
        id: 'job-a',
        label: 'Docs backup',
        sourceFolder: temp.path,
        destinationFolder: '${temp.path}/no/such/folder',
        enabled: false,
      ),
    ];
    final container = await pumpView(tester);

    await tester.tap(find.text('Back up now'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Failed'), findsOneWidget);
    expect(
      find.text(
        'Cannot write to the destination folder. Choose a different folder or check permissions.',
      ),
      findsOneWidget,
    );
    final log = await store.readRunLog();
    expect(log.single.jobLabel, 'Docs backup');
    expect(log.single.archiveName, isNull);
    container.dispose();
  });

  testWidgets('A4: missing source shows the SPEC message', (tester) async {
    store.jobs = [
      BackupJob(
        id: 'job-a',
        label: 'Docs backup',
        sourceFolder: '${temp.path}/gone',
        destinationFolder: temp.path,
        enabled: false,
      ),
    ];
    final container = await pumpView(tester);

    await tester.tap(find.text('Back up now'));
    await tester.pumpAndSettle();

    expect(
      find.text('Source folder not found. Choose the folder again.'),
      findsOneWidget,
    );
    container.dispose();
  });

  testWidgets('A4 (es): failure message is localized', (tester) async {
    store.jobs = [
      BackupJob(
        id: 'job-a',
        label: 'Copia docs',
        sourceFolder: '${temp.path}/gone',
        destinationFolder: temp.path,
        enabled: false,
      ),
    ];
    final container = await pumpView(tester, locale: const Locale('es'));

    await tester.tap(find.text('Crear copia ahora'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'No se encontró la carpeta de origen. Elija la carpeta de nuevo.',
      ),
      findsOneWidget,
    );
    container.dispose();
  });

  testWidgets('offline shows the neutral note; controls stay enabled', (
    tester,
  ) async {
    connectivity.online = false;
    store.jobs = [tempJob()];
    final container = await pumpView(tester);

    expect(
      find.text('Backups use local folders only. No internet required.'),
      findsOneWidget,
    );
    final runNow = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Back up now'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(runNow.onPressed, isNotNull);
    container.dispose();
  });

  testWidgets('in-progress run disables run actions and shows running copy', (
    tester,
  ) async {
    final blocking = FakeBackupRepository(jobs: const [docsJob])
      ..blockRuns = true;
    final container = await pumpView(tester, repository: blocking);

    await tester.tap(find.text('Back up now'));
    await tester.pump();

    expect(find.text('Creating backup…'), findsWidgets);
    expect(find.text('Back up now'), findsNothing);

    blocking.completer.complete(
      Success<BackupRunLogEntry>(
        BackupRunLogEntry(
          jobId: 'job-a',
          jobLabel: 'Docs backup',
          finishedAt: DateTime.now().toUtc(),
          status: BackupRunStatus.succeeded,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Back up now'), findsOneWidget);
    expect(find.text('Backup complete'), findsOneWidget);
    container.dispose();
  });

  testWidgets('edit dialog pre-fills the job and saves changes', (
    tester,
  ) async {
    store.jobs = const [docsJob];
    final container = await pumpView(tester);

    await tester.tap(find.byTooltip('Edit'));
    await tester.pumpAndSettle();
    expect(find.text('Edit backup job'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Docs backup',
    );

    await tester.enterText(find.byType(TextField), 'Renamed backup');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Renamed backup'), findsOneWidget);
    expect(store.jobs.single.label, 'Renamed backup');
    expect(store.jobs.single.schedule.kind, BackupScheduleKind.weekly);
    container.dispose();
  });

  testWidgets('enabled toggle persists on the job', (tester) async {
    // Unconfigured so the scheduler never fires during the test.
    store.jobs = const [BackupJob(id: 'job-a', label: 'Docs backup')];
    final container = await pumpView(tester);

    final toggle = tester.widget<Switch>(find.byType(Switch));
    expect(toggle.value, isTrue);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(store.jobs.single.enabled, isFalse);
    container.dispose();
  });
}
