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
  String toolRowSemantics(String title, String subtitle) {
    return '$title, $subtitle';
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
  String get inventoryMoreActionsTooltip => 'More actions';

  @override
  String inventoryItemActionsTooltip(String name) {
    return 'Actions for $name';
  }

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
  String consolidatorMergeProgressSemantics(int percent) {
    return 'Merge progress $percent percent';
  }

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

  @override
  String get documentFactoryHeadline => 'Batch personalized PDFs';

  @override
  String documentFactoryDescription(String token) {
    return 'Choose an HTML template with $token tokens, pick a data sheet, map fields, and generate one PDF per row.';
  }

  @override
  String get documentFactoryTemplateSection => 'Template';

  @override
  String get documentFactoryDataSection => 'Data sheet';

  @override
  String get documentFactoryMappingSection => 'Map fields';

  @override
  String get documentFactoryOutputSection => 'Output folder';

  @override
  String get documentFactoryChooseTemplate => 'Choose template';

  @override
  String get documentFactoryChooseDataSheet => 'Choose data sheet';

  @override
  String get documentFactorySaveMapping => 'Save mapping';

  @override
  String get documentFactoryChooseOutputFolder => 'Choose output folder';

  @override
  String get documentFactoryGenerate => 'Generate PDFs';

  @override
  String get documentFactoryOpenOutputFolder => 'Open output folder';

  @override
  String get documentFactoryMappingSaved => 'Mapping saved';

  @override
  String get documentFactoryMapAllHint =>
      'Map all placeholders before generating';

  @override
  String get documentFactoryNoTemplate => 'No template selected';

  @override
  String get documentFactoryNoDataSheet => 'No data sheet selected';

  @override
  String get documentFactoryNoOutput => 'No output folder selected';

  @override
  String get documentFactoryMappingEmptyHint =>
      'Select a template and data sheet to map fields';

  @override
  String documentFactoryZeroPlaceholders(String token) {
    return 'No placeholders found in this template. Use a template with $token tokens.';
  }

  @override
  String get documentFactoryPartialTitle => 'Generated with some errors';

  @override
  String documentFactoryPartialCounts(int success, int failed) {
    return '$success PDFs created, $failed rows failed';
  }

  @override
  String get documentFactorySuccessTitle => 'PDFs generated';

  @override
  String documentFactorySuccessSummary(int count, String folderBasename) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count PDFs saved to $folderBasename',
      one: '1 PDF saved to $folderBasename',
    );
    return '$_temp0';
  }

  @override
  String get documentFactoryErrorBatchTitle => 'Batch failed';

  @override
  String get documentFactoryErrorTemplate =>
      'Could not read the template file. Choose a different file.';

  @override
  String get documentFactoryErrorSheet =>
      'Could not read the data sheet. Choose a different .xlsx file.';

  @override
  String get documentFactoryErrorOutput =>
      'Cannot write to the output folder. Choose a folder where you have permission to save files.';

  @override
  String get documentFactoryErrorGeneric =>
      'Something went wrong during PDF generation.';

  @override
  String get documentFactoryDuplicateHeaders =>
      'The data sheet has duplicate column headers. Fix the sheet and try again.';

  @override
  String get documentFactoryRowRenderFailure =>
      'Could not create PDF for this row';

  @override
  String documentFactoryEmptyRowsSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count empty rows skipped',
      one: '1 empty row skipped',
    );
    return '$_temp0';
  }

  @override
  String documentFactoryProgress(int done, int total) {
    return 'Generating PDFs… $done of $total';
  }

  @override
  String documentFactoryProgressAnnouncement(int done, int total) {
    return '$done of $total PDFs generated';
  }

  @override
  String get documentFactoryInterrupted =>
      'The last job did not finish. You can start a new batch.';

  @override
  String get documentFactoryMappingSaveError =>
      'Could not save mapping. Try again.';

  @override
  String documentFactoryFailureRow(int n, String message) {
    return 'Row $n: $message';
  }

  @override
  String get documentFactoryTryAgain => 'Try again';

  @override
  String get documentFactoryLoading => 'Loading…';

  @override
  String documentFactoryPlaceholderCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count placeholders',
      one: '1 placeholder',
    );
    return '$_temp0';
  }

  @override
  String documentFactorySheetRowCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count data rows',
      one: '1 data row',
    );
    return '$_temp0';
  }

  @override
  String documentFactorySheetColumnCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count columns',
      one: '1 column',
    );
    return '$_temp0';
  }

  @override
  String get documentFactorySelectColumn => 'Select column';

  @override
  String documentFactoryColumnFor(String placeholder) {
    return 'Column for $placeholder';
  }

  @override
  String documentFactoryRowsFailedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rows failed',
      one: '1 row failed',
    );
    return '$_temp0';
  }

  @override
  String get documentFactoryRevealError =>
      'Could not open the output folder on this desktop.';

  @override
  String get priceMonitorIntro =>
      'Track product prices and get notified when one crosses your threshold.';

  @override
  String get priceMonitorAddWatch => 'Add watch';

  @override
  String get priceMonitorLoading => 'Loading watches…';

  @override
  String get priceMonitorEmptyTitle => 'No price watches yet';

  @override
  String get priceMonitorEmptyMessage =>
      'Add a watch to get notified when a price crosses your threshold.';

  @override
  String get priceMonitorNotFetched => 'Not fetched yet';

  @override
  String get priceMonitorFetchFailed => 'Fetch failed';

  @override
  String get priceMonitorParseFailed => 'Could not read price from page';

  @override
  String get priceMonitorRetryNow => 'Retry now';

  @override
  String get priceMonitorLoadErrorTitle => 'Could not load watches';

  @override
  String get priceMonitorLoadErrorMessage =>
      'Try closing and reopening the app.';

  @override
  String get priceMonitorTryAgain => 'Try again';

  @override
  String get priceMonitorOfflineBadge => 'Offline — price checks paused';

  @override
  String get priceMonitorOfflineSemantics => 'Offline, price checks paused';

  @override
  String get priceMonitorOfflineChip => 'Offline';

  @override
  String priceMonitorUpdated(String time) {
    return 'Updated $time';
  }

  @override
  String priceMonitorAlertLine(String direction, String threshold) {
    return 'Alert $direction $threshold';
  }

  @override
  String get priceMonitorAbove => 'Above';

  @override
  String get priceMonitorBelow => 'Below';

  @override
  String get priceMonitorThresholdError =>
      'Enter a threshold greater than zero';

  @override
  String get priceMonitorUrlError =>
      'Enter a valid web address starting with http:// or https://';

  @override
  String get priceMonitorLabelError => 'Enter a label';

  @override
  String get priceMonitorLabelTooLongError =>
      'Keep the label under 120 characters';

  @override
  String get priceMonitorDeleteConfirmTitle => 'Delete this watch?';

  @override
  String get priceMonitorDeleteConfirmMessage =>
      'The watch stops being polled and its last-known price is removed.';

  @override
  String get priceMonitorDelete => 'Delete';

  @override
  String get priceMonitorCancel => 'Cancel';

  @override
  String get priceMonitorSave => 'Save';

  @override
  String get priceMonitorDiscardTitle => 'Discard unsaved changes?';

  @override
  String get priceMonitorDiscard => 'Discard';

  @override
  String get priceMonitorKeepEditing => 'Keep editing';

  @override
  String priceMonitorAlertTitle(String label) {
    return 'Price alert: $label';
  }

  @override
  String priceMonitorAlertBody(String price, String threshold) {
    return 'Price is $price (threshold $threshold)';
  }

  @override
  String get priceMonitorDismiss => 'Dismiss';

  @override
  String get priceMonitorMacNotifyHint =>
      'Allow notifications in System Settings to get price alerts on the desktop.';

  @override
  String get priceMonitorEditorTitleNew => 'Add watch';

  @override
  String get priceMonitorEditorTitleEdit => 'Edit watch';

  @override
  String get priceMonitorFieldLabel => 'Label';

  @override
  String get priceMonitorFieldUrl => 'URL';

  @override
  String get priceMonitorFieldThreshold => 'Threshold';

  @override
  String get priceMonitorNotifyWhen => 'Notify when';

  @override
  String get priceMonitorEnabled => 'Enabled';

  @override
  String priceMonitorToggleSemantics(String label) {
    return 'Enable watch $label';
  }

  @override
  String priceMonitorRowSemantics(
    String label,
    String price,
    String time,
    String direction,
    String threshold,
    String state,
  ) {
    return '$label, last price $price, updated $time, alert $direction $threshold, $state';
  }

  @override
  String get priceMonitorStateEnabled => 'enabled';

  @override
  String get priceMonitorStateDisabled => 'disabled';

  @override
  String get priceMonitorEdit => 'Edit';

  @override
  String get priceMonitorSaveError => 'Could not save the watch. Try again.';

  @override
  String get priceMonitorErrorGeneric => 'Something went wrong. Try again.';

  @override
  String get backupLoading => 'Loading…';

  @override
  String get backupSettingsSection => 'Backup settings';

  @override
  String get backupSourceFolderLabel => 'Source folder';

  @override
  String get backupDestinationFolderLabel => 'Destination folder';

  @override
  String get backupChooseSource => 'Choose source folder';

  @override
  String get backupChooseDestination => 'Choose destination folder';

  @override
  String get backupNoSourceSelected => 'No source folder selected';

  @override
  String get backupNoDestinationSelected => 'No destination folder selected';

  @override
  String get backupDailyRunHour => 'Daily run hour';

  @override
  String get backupEnableSchedule => 'Enable daily schedule';

  @override
  String get backupRunNow => 'Back up now';

  @override
  String get backupRunning => 'Creating backup…';

  @override
  String backupProgressFiles(int processed, int total) {
    return '$processed of $total files';
  }

  @override
  String get backupLastRunSection => 'Last run';

  @override
  String get backupLastRunSucceeded => 'Last backup: succeeded';

  @override
  String get backupLastRunFailed => 'Last backup: failed';

  @override
  String get backupLastRunUnknown => 'Last backup: unknown';

  @override
  String get backupNoBackupsYet => 'No backups yet';

  @override
  String get backupArchivesSection => 'Recent archives';

  @override
  String get backupNoArchivesYet => 'No archives yet';

  @override
  String get backupNoArchivesHelper => 'Run a backup to see archives here.';

  @override
  String get backupComplete => 'Backup complete';

  @override
  String get backupDismiss => 'Dismiss';

  @override
  String get backupOfflineNote =>
      'Backups use local folders only. No internet required.';

  @override
  String get backupLoadErrorTitle => 'Could not load backup settings';

  @override
  String get backupLoadError => 'Could not load backup settings. Try again.';

  @override
  String get backupRetry => 'Retry';

  @override
  String get backupFolderSelectionCancelled => 'Folder selection cancelled.';

  @override
  String get backupShowInFolder => 'Show in file manager';

  @override
  String backupArchiveRowSemantics(String name, String date, String size) {
    return '$name, $date, $size';
  }

  @override
  String get backupErrorSourceMissing =>
      'Source folder not found. Choose the folder again.';

  @override
  String get backupErrorDestinationNotWritable =>
      'Cannot write to the destination folder. Choose a different folder or check permissions.';

  @override
  String get backupErrorSourceNotReadable =>
      'Cannot read the source folder. Check permissions.';

  @override
  String get backupErrorDiskFull =>
      'Not enough space in the destination folder.';

  @override
  String get backupErrorSameFolders =>
      'Source and destination must be different folders.';

  @override
  String get backupErrorInterrupted => 'Backup was interrupted.';

  @override
  String get backupErrorPathTooLong =>
      'Path is too long for this system. Choose a shorter destination.';

  @override
  String get backupErrorGeneric =>
      'Backup failed. Try again or check the folders.';
}
