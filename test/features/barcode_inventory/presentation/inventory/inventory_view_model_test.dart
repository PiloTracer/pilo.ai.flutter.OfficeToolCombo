import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:office_tool_combo/core/error/failure.dart';
import 'package:office_tool_combo/core/result/result.dart';
import 'package:office_tool_combo/core/storage/app_database.dart'
    hide InventoryItem, ScanEvent;
import 'package:office_tool_combo/features/barcode_inventory/data/repositories/inventory_repository_impl.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/entities/multi_image_decode_outcome.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/entities/scan_event.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/failures/inventory_failure.dart';
import 'package:office_tool_combo/features/barcode_inventory/domain/repositories/inventory_repository.dart';
import 'package:office_tool_combo/features/barcode_inventory/presentation/inventory/inventory_providers.dart';
import 'package:office_tool_combo/features/barcode_inventory/presentation/inventory/inventory_ui_state.dart';
import 'package:office_tool_combo/features/barcode_inventory/presentation/inventory/inventory_view_model.dart';
import 'package:office_tool_combo/l10n/generated/app_localizations_en.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late ProviderContainer container;
  late Directory tempDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase.inMemory();
    container = ProviderContainer(
      overrides: [
        inventoryRepositoryProvider.overrideWithValue(
          InventoryRepositoryImpl(database: database),
        ),
      ],
    );
    tempDir = await Directory.systemTemp.createTemp('inventory_vm_');
  });

  tearDown(() async {
    container.dispose();
    await database.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('loadInventory moves to success with empty list', () async {
    final viewModel = container.read(inventoryViewModelProvider.notifier);
    await viewModel.loadInventory();

    final state = container.read(inventoryViewModelProvider);
    expect(state.phase, InventoryPhase.empty);
    expect(state.items, isEmpty);
  });

  test('submitScan for unknown barcode sets pending create', () async {
    final viewModel = container.read(inventoryViewModelProvider.notifier);
    await viewModel.loadInventory();

    final result = await viewModel.submitScan('UNKNOWN-999');
    expect(result, isA<ScanSubmissionResult>());

    final state = container.read(inventoryViewModelProvider);
    expect(state.pendingUnknownBarcode, 'UNKNOWN-999');
  });

  test('confirmCreateItem adds item to state', () async {
    final viewModel = container.read(inventoryViewModelProvider.notifier);
    await viewModel.loadInventory();

    await viewModel.confirmCreateItem(
      barcode: 'NEW-1',
      name: 'Manual item',
      startingQuantity: 2,
    );

    final state = container.read(inventoryViewModelProvider);
    expect(state.items, hasLength(1));
    expect(state.items.first.name, 'Manual item');
    expect(state.toastMessage, 'Added Manual item');
  });

  test('setSearchQuery filters items in derived list', () async {
    final viewModel = container.read(inventoryViewModelProvider.notifier);
    await viewModel.loadInventory();
    await viewModel.confirmCreateItem(
      barcode: 'bolt-99',
      name: 'Big bolt',
      startingQuantity: 1,
    );
    await viewModel.confirmCreateItem(
      barcode: 'nut-99',
      name: 'Small nut',
      startingQuantity: 1,
    );

    viewModel.setSearchQuery('bolt');
    expect(viewModel.filteredItems, hasLength(1));
    expect(viewModel.filteredItems.first.barcode, 'bolt-99');
  });

  test('setScanMode updates mode', () {
    final viewModel = container.read(inventoryViewModelProvider.notifier);
    viewModel.setScanMode(ScanMode.ship);
    expect(container.read(inventoryViewModelProvider).scanMode, ScanMode.ship);
  });

  test(
    'importCsvFile wires skipped/duplicate counts into state; dismiss clears',
    () async {
      final csvFile = File('${tempDir.path}/import.csv');
      await csvFile.writeAsString(
        'barcode,name,description,sku,quantity_on_hand,updated_at\n'
        'A-1,Widget,,A-1,5,\n'
        'A-1,Widget v2,,A-1,7,\n'
        'B-2,Gadget,,B-2,not-a-number,\n'
        'C-3,,,C-3,2,\n',
      );

      final viewModel = container.read(inventoryViewModelProvider.notifier);
      await viewModel.loadInventory();
      await viewModel.importCsvFile(csvFile.path);

      var state = container.read(inventoryViewModelProvider);
      expect(state.items, hasLength(1));
      expect(state.items.first.name, 'Widget v2');
      expect(state.items.first.quantityOnHand, 7);
      // 2 invalid rows skipped + 1 duplicate merged.
      expect(state.skippedRowCount, 3);
      expect(state.phase, InventoryPhase.partial);
      expect(state.toastMessage, contains('Imported 1 item'));
      expect(state.toastMessage, contains('2 rows skipped'));
      expect(state.toastMessage, contains('1 duplicate merged'));

      viewModel.dismissSkippedRows();
      state = container.read(inventoryViewModelProvider);
      expect(state.skippedRowCount, 0);
      expect(state.phase, InventoryPhase.success);
    },
  );

  test('importCsvFile surfaces a localized error for a bad CSV', () async {
    final csvFile = File('${tempDir.path}/bad.csv');
    await csvFile.writeAsString('foo,bar\n1,2\n');

    final viewModel = container.read(inventoryViewModelProvider.notifier);
    await viewModel.loadInventory();
    await viewModel.importCsvFile(csvFile.path);

    final state = container.read(inventoryViewModelProvider);
    expect(
      state.errorMessage,
      'CSV must include barcode, name, and quantity_on_hand columns',
    );
  });

  group('scan flows and mutations', () {
    Future<InventoryViewModel> loadWithItem({
      String barcode = 'R-1',
      String name = 'Hex bolt',
      int startingQuantity = 3,
    }) async {
      final viewModel = container.read(inventoryViewModelProvider.notifier);
      await viewModel.loadInventory();
      await viewModel.confirmCreateItem(
        barcode: barcode,
        name: name,
        startingQuantity: startingQuantity,
      );
      return viewModel;
    }

    InventoryUiState readState() => container.read(inventoryViewModelProvider);

    test('blank scan is cleared without touching state', () async {
      final viewModel = container.read(inventoryViewModelProvider.notifier);
      await viewModel.loadInventory();

      final result = await viewModel.submitScan('   ');

      expect(result, isA<ScanSubmissionResult>());
      var cleared = false;
      result.when(
        cleared: () => cleared = true,
        handled: () {},
        needsCreate: () {},
        needsCount: (_) {},
        failed: (_) {},
      );
      expect(cleared, isTrue);
      expect(readState().pendingUnknownBarcode, isNull);
    });

    test('receive scan increments quantity with a scan toast', () async {
      final viewModel = await loadWithItem();

      final result = await viewModel.submitScan('R-1');

      var handled = false;
      result.when(
        cleared: () {},
        handled: () => handled = true,
        needsCreate: () {},
        needsCount: (_) {},
        failed: (_) {},
      );
      expect(handled, isTrue);
      final state = readState();
      expect(state.items.single.quantityOnHand, 4);
      expect(state.toastMessage, 'Received Hex bolt: 4');
      expect(state.recentScans, isNotEmpty);
    });

    test('ship scan decrements quantity', () async {
      final viewModel = await loadWithItem();
      viewModel.setScanMode(ScanMode.ship);

      await viewModel.submitScan('R-1');

      final state = readState();
      expect(state.items.single.quantityOnHand, 2);
      expect(state.toastMessage, 'Shipped Hex bolt: 2');
    });

    test(
      'ship scan with insufficient stock fails by code and toasts',
      () async {
        final viewModel = await loadWithItem(startingQuantity: 0);
        viewModel.setScanMode(ScanMode.ship);

        final result = await viewModel.submitScan('R-1');

        var failedMessage = '';
        result.when(
          cleared: () {},
          handled: () {},
          needsCreate: () {},
          needsCount: (_) {},
          failed: (message) => failedMessage = message,
        );
        // The insufficient-stock failure is identified by its code, which the
        // l10n mapper turns into this message.
        expect(
          failedMessage,
          AppLocalizationsEn().inventoryFailureInsufficient,
        );
        final state = readState();
        expect(state.toastMessage, failedMessage);
        expect(state.errorMessage, isNull);
        expect(state.items.single.quantityOnHand, 0);
      },
    );

    test(
      'count scan on known item asks for a quantity, then sets it',
      () async {
        final viewModel = await loadWithItem();
        viewModel.setScanMode(ScanMode.count);

        final result = await viewModel.submitScan('R-1');

        var askedQty = -1;
        result.when(
          cleared: () {},
          handled: () {},
          needsCreate: () {},
          needsCount: (currentQty) => askedQty = currentQty,
          failed: (_) {},
        );
        expect(askedQty, 3);
        expect(readState().pendingCountBarcode, 'R-1');

        final confirm = await viewModel.confirmCountQuantity(
          barcode: 'R-1',
          quantity: 11,
        );
        var handled = false;
        confirm.when(
          cleared: () {},
          handled: () => handled = true,
          needsCreate: () {},
          needsCount: (_) {},
          failed: (_) {},
        );
        expect(handled, isTrue);
        final state = readState();
        expect(state.items.single.quantityOnHand, 11);
        expect(state.toastMessage, 'Updated Hex bolt: 11');
        expect(state.pendingCountBarcode, isNull);
      },
    );

    test('count scan on unknown item routes to the create flow', () async {
      final viewModel = container.read(inventoryViewModelProvider.notifier);
      await viewModel.loadInventory();
      viewModel.setScanMode(ScanMode.count);

      final result = await viewModel.submitScan('GHOST-1');

      var needsCreate = false;
      result.when(
        cleared: () {},
        handled: () {},
        needsCreate: () => needsCreate = true,
        needsCount: (_) {},
        failed: (_) {},
      );
      expect(needsCreate, isTrue);
      expect(readState().pendingUnknownBarcode, 'GHOST-1');
    });

    test(
      'unknown identifier flow creates the item and clears pending',
      () async {
        final viewModel = container.read(inventoryViewModelProvider.notifier);
        await viewModel.loadInventory();

        await viewModel.submitScan('X-1');
        expect(readState().pendingUnknownBarcode, 'X-1');

        await viewModel.confirmCreateItem(
          barcode: 'X-1',
          name: 'Created from scan',
          startingQuantity: 5,
        );

        final state = readState();
        expect(state.items.single.name, 'Created from scan');
        expect(state.pendingUnknownBarcode, isNull);
        expect(state.toastMessage, 'Added Created from scan');
      },
    );

    test('confirmCreateItem duplicate surfaces a failed result', () async {
      final viewModel = await loadWithItem();

      final result = await viewModel.confirmCreateItem(
        barcode: 'R-1',
        name: 'Duplicate',
        startingQuantity: 1,
      );

      var failedMessage = '';
      result.when(
        cleared: () {},
        handled: () {},
        needsCreate: () {},
        needsCount: (_) {},
        failed: (message) => failedMessage = message,
      );
      expect(failedMessage, AppLocalizationsEn().inventoryFailureDuplicate);
      expect(readState().errorMessage, failedMessage);
    });

    test('cancelPendingDialog clears both pending barcodes', () async {
      final viewModel = container.read(inventoryViewModelProvider.notifier);
      await viewModel.loadInventory();
      await viewModel.submitScan('PENDING-1');
      expect(readState().pendingUnknownBarcode, 'PENDING-1');

      viewModel.cancelPendingDialog();

      final state = readState();
      expect(state.pendingUnknownBarcode, isNull);
      expect(state.pendingCountBarcode, isNull);
    });

    test('updateItem edits name, description and quantity', () async {
      final viewModel = await loadWithItem();
      final id = readState().items.single.id;

      await viewModel.updateItem(
        id: id,
        name: 'Renamed bolt',
        description: 'Shelf B2',
        quantityOnHand: 7,
      );

      final state = readState();
      expect(state.items.single.name, 'Renamed bolt');
      expect(state.items.single.description, 'Shelf B2');
      expect(state.items.single.quantityOnHand, 7);
      expect(state.toastMessage, 'Updated Renamed bolt: 7');
    });

    test('deleteItem removes the item', () async {
      final viewModel = await loadWithItem();
      final id = readState().items.single.id;

      await viewModel.deleteItem(id);

      final state = readState();
      expect(state.items, isEmpty);
      expect(state.phase, InventoryPhase.empty);
      expect(state.toastMessage, 'Item deleted');
    });

    test('clearToast clears only the toast message', () async {
      final viewModel = await loadWithItem();
      expect(readState().toastMessage, isNotNull);

      viewModel.clearToast();

      expect(readState().toastMessage, isNull);
      expect(readState().items, hasLength(1));
    });

    test(
      'setSearchQuery stores the query and toggles isSearchActive',
      () async {
        final viewModel = await loadWithItem();

        expect(viewModel.isSearchActive, isFalse);
        viewModel.setSearchQuery('  ');
        expect(viewModel.isSearchActive, isFalse);
        viewModel.setSearchQuery('bolt');
        expect(viewModel.isSearchActive, isTrue);
        expect(readState().searchQuery, 'bolt');
        expect(viewModel.filteredItemCount, 1);
      },
    );

    test('dismissSkippedRows is a no-op when nothing was skipped', () async {
      final viewModel = await loadWithItem();
      expect(readState().skippedRowCount, 0);

      viewModel.dismissSkippedRows();

      expect(readState().phase, InventoryPhase.success);
      expect(readState().skippedRowCount, 0);
    });
  });

  group('export and image decode flows (mocked repository)', () {
    late _MockInventoryRepository repository;
    late ProviderContainer mockContainer;

    setUp(() {
      repository = _MockInventoryRepository();
      mockContainer = ProviderContainer(
        overrides: [inventoryRepositoryProvider.overrideWithValue(repository)],
      );
    });

    tearDown(() => mockContainer.dispose());

    InventoryViewModel mockViewModel() =>
        mockContainer.read(inventoryViewModelProvider.notifier);

    InventoryUiState mockState() =>
        mockContainer.read(inventoryViewModelProvider);

    void stubExport(Result<String?> result) {
      when(
        () => repository.exportInventoryCsv(
          dialogTitle: any(named: 'dialogTitle'),
        ),
      ).thenAnswer((_) async => result);
    }

    test('exportCsv stores the path and toast on success', () async {
      stubExport(const Success<String?>('/tmp/out.csv'));

      await mockViewModel().exportCsv();

      expect(mockState().lastExportPath, '/tmp/out.csv');
      expect(mockState().toastMessage, 'Exported inventory to /tmp/out.csv');
      expect(mockState().errorMessage, isNull);
    });

    test('exportCsv with a cancelled picker leaves state untouched', () async {
      stubExport(const Success<String?>(null));

      await mockViewModel().exportCsv();

      expect(mockState().toastMessage, isNull);
      expect(mockState().lastExportPath, isNull);
      expect(mockState().errorMessage, isNull);
    });

    test('exportCsv failure surfaces a localized error message', () async {
      stubExport(const Err<String?>(IoFailure(InventoryFailureCodes.export)));

      await mockViewModel().exportCsv();

      expect(
        mockState().errorMessage,
        AppLocalizationsEn().inventoryFailureExport,
      );
      expect(mockState().lastExportPath, isNull);
    });

    test(
      'pickAndDecodeImages toasts and returns null when picking fails',
      () async {
        when(
          () => repository.pickBarcodeImagePaths(
            dialogTitle: any(named: 'dialogTitle'),
          ),
        ).thenAnswer(
          (_) async =>
              const Err<List<String>>(IoFailure(InventoryFailureCodes.decode)),
        );

        final outcome = await mockViewModel().pickAndDecodeImages();

        expect(outcome, isNull);
        expect(
          mockState().toastMessage,
          AppLocalizationsEn().inventoryFailureDecode,
        );
        expect(mockState().isDecodingImages, isFalse);
      },
    );

    test('pickAndDecodeImages returns null when nothing was picked', () async {
      when(
        () => repository.pickBarcodeImagePaths(
          dialogTitle: any(named: 'dialogTitle'),
        ),
      ).thenAnswer((_) async => const Success<List<String>>([]));

      final outcome = await mockViewModel().pickAndDecodeImages();

      expect(outcome, isNull);
      expect(mockState().toastMessage, isNull);
      expect(mockState().isDecodingImages, isFalse);
    });

    test('pickAndDecodeImages returns the outcome on success', () async {
      when(
        () => repository.pickBarcodeImagePaths(
          dialogTitle: any(named: 'dialogTitle'),
        ),
      ).thenAnswer((_) async => const Success<List<String>>(['/tmp/a.png']));
      when(() => repository.decodeBarcodeImagePaths(['/tmp/a.png'])).thenAnswer(
        (_) async => const Success(
          MultiImageDecodeOutcome(
            decodedBarcodes: ['X-1'],
            failedFileNames: [],
          ),
        ),
      );

      final outcome = await mockViewModel().pickAndDecodeImages();

      expect(outcome, isNotNull);
      expect(outcome!.decodedBarcodes, ['X-1']);
      expect(mockState().isDecodingImages, isFalse);
    });

    test(
      'pickAndDecodeImages returns null for a fully empty outcome',
      () async {
        when(
          () => repository.pickBarcodeImagePaths(
            dialogTitle: any(named: 'dialogTitle'),
          ),
        ).thenAnswer((_) async => const Success<List<String>>(['/tmp/a.png']));
        when(
          () => repository.decodeBarcodeImagePaths(['/tmp/a.png']),
        ).thenAnswer(
          (_) async => const Success(
            MultiImageDecodeOutcome(decodedBarcodes: [], failedFileNames: []),
          ),
        );

        final outcome = await mockViewModel().pickAndDecodeImages();

        expect(outcome, isNull);
        expect(mockState().isDecodingImages, isFalse);
      },
    );

    test(
      'pickAndDecodeImages returns the outcome when decodes failed',
      () async {
        when(
          () => repository.pickBarcodeImagePaths(
            dialogTitle: any(named: 'dialogTitle'),
          ),
        ).thenAnswer((_) async => const Success<List<String>>(['/tmp/a.png']));
        when(
          () => repository.decodeBarcodeImagePaths(['/tmp/a.png']),
        ).thenAnswer(
          (_) async => const Success(
            MultiImageDecodeOutcome(
              decodedBarcodes: [],
              failedFileNames: ['a.png'],
            ),
          ),
        );

        final outcome = await mockViewModel().pickAndDecodeImages();

        // Not "empty": the caller still needs failedFileNames for the summary.
        expect(outcome, isNotNull);
        expect(outcome!.failedFileNames, ['a.png']);
        expect(mockState().isDecodingImages, isFalse);
      },
    );

    test('pickAndDecodeImages toasts when decoding fails', () async {
      when(
        () => repository.pickBarcodeImagePaths(
          dialogTitle: any(named: 'dialogTitle'),
        ),
      ).thenAnswer((_) async => const Success<List<String>>(['/tmp/a.png']));
      when(() => repository.decodeBarcodeImagePaths(['/tmp/a.png'])).thenAnswer(
        (_) async => const Err<MultiImageDecodeOutcome>(
          IoFailure(InventoryFailureCodes.decode),
        ),
      );

      final outcome = await mockViewModel().pickAndDecodeImages();

      expect(outcome, isNull);
      expect(
        mockState().toastMessage,
        AppLocalizationsEn().inventoryFailureDecode,
      );
      expect(mockState().isDecodingImages, isFalse);
    });
  });
}

class _MockInventoryRepository extends Mock implements InventoryRepository {}
