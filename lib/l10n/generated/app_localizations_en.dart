// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'OfficeToolCombo';

  @override
  String get homeTagline =>
      'Five desk tools for everyday office work — no terminal, no IT ticket.';

  @override
  String get homeChooseTool => 'Choose a tool';

  @override
  String get toolReportConsolidatorTitle => 'Report consolidator';

  @override
  String get toolReportConsolidatorSubtitle =>
      'Merge a folder of Excel files into one clean workbook';

  @override
  String get toolBarcodeInventoryTitle => 'Barcode inventory';

  @override
  String get toolBarcodeInventorySubtitle =>
      'Scan products with a USB wedge reader and track stock';

  @override
  String get toolDocumentFactoryTitle => 'Document factory';

  @override
  String get toolDocumentFactorySubtitle =>
      'Turn Excel rows into personalized PDFs';

  @override
  String get toolPriceMonitorTitle => 'Price monitor';

  @override
  String get toolPriceMonitorSubtitle =>
      'Watch prices in the background and get notified';

  @override
  String get toolScheduledBackupTitle => 'Scheduled backup';

  @override
  String get toolScheduledBackupSubtitle =>
      'Zip a folder on a schedule with a dated archive name';

  @override
  String get comingSoonBadge => 'Soon';

  @override
  String toolComingSoonSemantics(String title) {
    return '$title, coming soon';
  }

  @override
  String get backToHomeTooltip => 'Back to home';

  @override
  String get placeholderHeadline => 'Coming in the next milestone';

  @override
  String placeholderMessage(String tool, String toolId) {
    return '$tool is on the roadmap. The navigation shell is ready; full workflow for $toolId ships in a later release.';
  }

  @override
  String get languageMenuLabel => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Español';

  @override
  String get inventoryTitle => 'Barcode inventory';

  @override
  String get inventoryIntro =>
      'Scan products with a USB or Bluetooth wedge reader, upload one or more barcode images, or enter identifiers manually. Supports QR codes, linear barcodes, and alphanumeric SKUs.';

  @override
  String get inventoryImportCsv => 'Import CSV';

  @override
  String get inventoryExportCsv => 'Export CSV';

  @override
  String get inventoryManualEntry => 'Manual entry';

  @override
  String get inventoryScanFromImages => 'Scan from images';

  @override
  String get inventorySearchStockLabel => 'Search stock';

  @override
  String get inventorySearchStockHint =>
      'Name, barcode, notes — typos & accents OK';

  @override
  String get inventoryClearSearchTooltip => 'Clear search';

  @override
  String inventorySearchMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count matches',
      one: '1 match',
    );
    return '$_temp0';
  }

  @override
  String get inventoryDecodingImagesTitle => 'Reading barcodes from images…';

  @override
  String get inventoryDecodingImagesSubtitle =>
      'You can still move the window while this runs.';

  @override
  String inventoryItemsChip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String inventoryUnitsChip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count units on hand',
      one: '1 unit on hand',
    );
    return '$_temp0';
  }

  @override
  String get inventoryOfflineBadge => 'Working offline';

  @override
  String get inventoryLoading => 'Loading inventory…';

  @override
  String get inventoryLoadErrorTitle => 'Could not load inventory';

  @override
  String get inventoryGenericError => 'Something went wrong';

  @override
  String get inventoryRetry => 'Try again';

  @override
  String get inventoryEmptyTitle => 'No items yet';

  @override
  String get inventoryEmptyMessage => 'Scan a barcode to add your first item.';

  @override
  String get inventoryNoMatchingItems => 'No matching items';

  @override
  String inventoryImportSkippedBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rows from the last import were skipped or merged',
      one: '1 row from the last import was skipped or merged',
    );
    return '$_temp0';
  }

  @override
  String get inventoryDismiss => 'Dismiss';

  @override
  String get inventoryDeleteTitle => 'Delete item?';

  @override
  String inventoryDeleteMessage(String name) {
    return 'Remove \"$name\" from inventory?';
  }

  @override
  String get inventoryCancel => 'Cancel';

  @override
  String get inventoryDelete => 'Delete';

  @override
  String get inventoryImportConfirmTitle => 'Replace current inventory?';

  @override
  String get inventoryImportConfirmMessage =>
      'Importing a CSV replaces ALL current items. This cannot be undone.';

  @override
  String get inventoryImportConfirmAction => 'Import';

  @override
  String get inventoryScanFieldLabel => 'Scan barcode';

  @override
  String get inventoryScanFieldHint => 'Scan barcode…';

  @override
  String get inventoryScanFieldSemantics => 'Barcode scan field';

  @override
  String inventoryItemSemantics(String name, String barcode, int quantity) {
    return '$name, barcode $barcode, quantity $quantity';
  }

  @override
  String inventoryQuantityChip(int quantity) {
    return 'Qty: $quantity';
  }

  @override
  String get inventoryEditItem => 'Edit item';

  @override
  String get inventoryDeleteItem => 'Delete item';

  @override
  String get inventoryRecentScans => 'Recent scans';

  @override
  String get inventoryNewItemTitle => 'New item';

  @override
  String get inventoryNewItemSemantics => 'New item dialog';

  @override
  String get inventoryBarcodeIdentifierLabel => 'Barcode / identifier';

  @override
  String get inventoryItemNameLabel => 'Item name';

  @override
  String get inventoryErrorEnterName => 'Enter an item name';

  @override
  String get inventoryErrorInvalidQuantity => 'Enter a valid quantity';

  @override
  String get inventoryStartingQuantityLabel => 'Starting quantity';

  @override
  String get inventoryQuantityHelperNavigation =>
      '↑/↓ or +/− to adjust · Enter for next · Shift+Enter for previous';

  @override
  String get inventoryDescriptionLabel => 'Description';

  @override
  String get inventoryDescriptionHint =>
      'Optional notes (size, location, supplier…)';

  @override
  String get inventoryAddItem => 'Add item';

  @override
  String get inventoryCountQuantityTitle => 'Set counted quantity';

  @override
  String inventoryIdentifierLine(String barcode) {
    return 'Identifier: $barcode';
  }

  @override
  String get inventoryQuantityOnHandLabel => 'Quantity on hand';

  @override
  String get inventoryQuantityHelperConfirm =>
      '↑/↓ or +/− to adjust · Enter to confirm';

  @override
  String get inventorySetQuantity => 'Set quantity';

  @override
  String get inventorySave => 'Save';

  @override
  String get inventoryManualEntryTitle => 'Enter identifier manually';

  @override
  String get inventoryManualEntryLabel => 'Barcode / SKU / alphanumeric ID';

  @override
  String get inventoryManualEntryHint => 'Type or paste an identifier';

  @override
  String get inventoryErrorEnterBarcode => 'Enter a barcode or identifier';

  @override
  String get inventorySubmit => 'Submit';

  @override
  String inventoryToastAdded(String name) {
    return 'Added $name';
  }

  @override
  String inventoryToastUpdated(String name, int quantity) {
    return 'Updated $name: $quantity';
  }

  @override
  String inventoryToastScan(String verb, String name, int quantity) {
    return '$verb $name: $quantity';
  }

  @override
  String get inventoryVerbReceived => 'Received';

  @override
  String get inventoryVerbShipped => 'Shipped';

  @override
  String get inventoryVerbUpdated => 'Updated';

  @override
  String get inventoryToastDeleted => 'Item deleted';

  @override
  String inventoryToastExported(String path) {
    return 'Exported inventory to $path';
  }

  @override
  String inventoryToastImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Imported $count items',
      one: 'Imported 1 item',
    );
    return '$_temp0';
  }

  @override
  String inventoryImportSkippedPart(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rows skipped',
      one: '1 row skipped',
    );
    return '$_temp0';
  }

  @override
  String inventoryImportDuplicatesPart(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count duplicates merged',
      one: '1 duplicate merged',
    );
    return '$_temp0';
  }

  @override
  String inventoryErrorImport(String error) {
    return 'Could not import CSV: $error';
  }

  @override
  String inventoryBatchScansProcessed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count scans processed',
      one: '1 scan processed',
    );
    return '$_temp0';
  }

  @override
  String inventoryBatchImagesNoCode(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count images with no code found',
      one: '1 image with no code found',
    );
    return '$_temp0';
  }

  @override
  String get inventoryBatchNoBarcodes => 'No barcodes found in selected images';

  @override
  String get inventoryModeReceiveLabel => 'Receive';

  @override
  String get inventoryModeShipLabel => 'Ship';

  @override
  String get inventoryModeCountLabel => 'Count';

  @override
  String get inventoryModeReceiveDescription => 'Add 1 to stock on each scan';

  @override
  String get inventoryModeShipDescription => 'Remove 1 from stock on each scan';

  @override
  String get inventoryModeCountDescription => 'Set exact quantity after scan';

  @override
  String get inventoryFailureLoad => 'Could not load inventory';

  @override
  String get inventoryFailureSave => 'Could not save the scan';

  @override
  String get inventoryFailureCreate => 'Could not save the item';

  @override
  String get inventoryFailureDuplicate =>
      'An item with this barcode already exists';

  @override
  String get inventoryFailureInsufficient =>
      'Not enough stock to ship this quantity';

  @override
  String get inventoryFailureDecode =>
      'No barcode or QR code found in that image';

  @override
  String get inventoryFailureExport => 'Could not export inventory';

  @override
  String get inventoryFailureExportEmpty => 'Nothing to export yet';

  @override
  String get inventoryFailureImport => 'Could not import inventory';

  @override
  String get inventoryFailureImportEmpty => 'That CSV file is empty';

  @override
  String get inventoryFailureImportColumns =>
      'CSV must include barcode, name, and quantity_on_hand columns';

  @override
  String get inventoryFailureImportNoRows => 'No valid rows found in CSV';

  @override
  String get inventoryFailureValidationDescription => 'Description is too long';

  @override
  String get inventoryFailureValidationUnknown =>
      'Unknown item — create it first or switch to Receive mode';

  @override
  String get consolidatorTitle => 'Report consolidator';

  @override
  String get consolidatorHeadline => 'Merge Excel reports';

  @override
  String get consolidatorDescription =>
      'Pick a folder of .xlsx files. The app combines them into one workbook and lists any files that could not be read.';

  @override
  String get consolidatorOutputFolderTitle => 'Output folder';

  @override
  String get consolidatorOutputFolderDefault =>
      'Same as the source folder (default)';

  @override
  String get consolidatorChooseOutputFolder => 'Choose output folder';

  @override
  String get consolidatorUseSourceFolder => 'Use source folder';

  @override
  String get consolidatorChooseAndMerge => 'Choose folder and merge';

  @override
  String get consolidatorNoSpreadsheetsTitle => 'No spreadsheets found';

  @override
  String get consolidatorNoSpreadsheetsMessage =>
      'That folder did not contain any .xlsx files. Try a different folder with Excel reports inside.';

  @override
  String get consolidatorChooseAnotherFolder => 'Choose another folder';

  @override
  String get consolidatorPartialTitle => 'Merged with some failures';

  @override
  String get consolidatorSuccessTitle => 'Merge complete';

  @override
  String get consolidatorErrorTitle => 'Merge could not finish';

  @override
  String get consolidatorErrorFallback =>
      'Something went wrong while reading the files. Check that the folder is readable and try again.';

  @override
  String get consolidatorTryAgain => 'Try again';

  @override
  String consolidatorMergingProgress(int percent) {
    return 'Merging spreadsheets… $percent%';
  }

  @override
  String get consolidatorPreparing => 'Preparing merge…';

  @override
  String get consolidatorMergingHint =>
      'Large folders may take a minute. You can keep this window open.';

  @override
  String consolidatorSavedAs(String fileName) {
    return 'Saved as $fileName';
  }

  @override
  String get consolidatorSavedInOutput =>
      'Output saved in the chosen output folder.';

  @override
  String get consolidatorFailuresTitle => 'Files that need attention';

  @override
  String get consolidatorFailuresMessage =>
      'These files were skipped or could not be read. Fix or remove them and run merge again.';

  @override
  String get consolidatorFailureFallback => 'Could not read this workbook';

  @override
  String consolidatorFailedFileSemantics(String fileName) {
    return 'Failed file $fileName';
  }

  @override
  String get consolidatorRecentMerges => 'Recent merges';

  @override
  String get consolidatorHistoryEmpty =>
      'Completed merges appear here. Up to 20 are kept.';

  @override
  String get consolidatorOpenFileLocation => 'Open file location';

  @override
  String consolidatorMergedSemantics(String fileName, String time) {
    return 'Merged $fileName on $time';
  }

  @override
  String get warningSemanticLabel => 'Warning';

  @override
  String get routerPageNotFoundTitle => 'Page not found';

  @override
  String get routerPageNotFoundHeading => 'This page does not exist';

  @override
  String get routerPageNotFoundFallback => 'Check the address or return home.';
}
