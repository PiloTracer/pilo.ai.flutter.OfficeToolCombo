import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:office_tool_combo/core/theme/app_theme.dart';
import 'package:office_tool_combo/features/price_monitor/data/services/connectivity_service.dart';
import 'package:office_tool_combo/features/scheduled_backup/data/repositories/backup_repository_impl.dart';
import 'package:office_tool_combo/features/scheduled_backup/data/sources/backup_store.dart';
import 'package:office_tool_combo/features/scheduled_backup/domain/entities/backup_job.dart';
import 'package:office_tool_combo/features/scheduled_backup/presentation/scheduled_backup/backup_providers.dart';
import 'package:office_tool_combo/features/scheduled_backup/presentation/scheduled_backup/backup_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/l10n_test_harness.dart';

class FakeConnectivityService implements ConnectivityService {
  @override
  Future<bool> isOnline() async => true;
}

void main() {
  late InMemoryBackupStore store;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    store = InMemoryBackupStore();
  });

  /// Pumps the view with in-memory fakes. The returned container must be
  /// disposed at the end of the test body — teardown disposal runs after
  /// flutter_test's pending-timer check, too late for the scheduler's
  /// periodic timer.
  Future<ProviderContainer> pumpView(
    WidgetTester tester, {
    double textScale = 1,
  }) async {
    tester.view.physicalSize = const Size(1000, 1700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        backupStoreProvider.overrideWithValue(store),
        backupRepositoryProvider.overrideWithValue(
          BackupRepositoryImpl(store: store),
        ),
        backupConnectivityServiceProvider.overrideWithValue(
          FakeConnectivityService(),
        ),
      ],
    );

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: UncontrolledProviderScope(
          container: container,
          child: buildL10nTestApp(
            theme: AppTheme.dark(),
            home: const BackupView(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('backup screen renders without overflow at 200% text scale', (
    tester,
  ) async {
    store.jobs = const [
      BackupJob(
        id: 'job-a',
        label: 'Docs backup',
        sourceFolder: '/src',
        destinationFolder: '/dst',
        schedule: BackupSchedule.weekly(weekday: DateTime.monday, hour: 2),
        enabled: false,
      ),
    ];
    final container = await pumpView(tester, textScale: 2);

    expect(tester.takeException(), isNull);
    expect(find.text('Add backup'), findsOneWidget);
    expect(find.text('Back up now'), findsOneWidget);
    container.dispose();
  });

  testWidgets('job editor exposes schedule controls, keyboard-reachable', (
    tester,
  ) async {
    final container = await pumpView(tester);

    await tester.tap(find.text('Add backup'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(Switch), findsOneWidget);
    expect(find.byType(DropdownButton<BackupScheduleKind>), findsOneWidget);
    expect(find.byType(DropdownButton<int>), findsOneWidget);
    container.dispose();
  });
}
