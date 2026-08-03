import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'OfficeToolCombo'**
  String get appTitle;

  /// No description provided for @homeTagline.
  ///
  /// In en, this message translates to:
  /// **'Five desk tools for everyday office work — no terminal, no IT ticket.'**
  String get homeTagline;

  /// No description provided for @homeChooseTool.
  ///
  /// In en, this message translates to:
  /// **'Choose a tool'**
  String get homeChooseTool;

  /// No description provided for @toolReportConsolidatorTitle.
  ///
  /// In en, this message translates to:
  /// **'Report consolidator'**
  String get toolReportConsolidatorTitle;

  /// No description provided for @toolReportConsolidatorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Merge a folder of Excel files into one clean workbook'**
  String get toolReportConsolidatorSubtitle;

  /// No description provided for @toolBarcodeInventoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Barcode inventory'**
  String get toolBarcodeInventoryTitle;

  /// No description provided for @toolBarcodeInventorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scan products with a USB wedge reader and track stock'**
  String get toolBarcodeInventorySubtitle;

  /// No description provided for @toolDocumentFactoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Document factory'**
  String get toolDocumentFactoryTitle;

  /// No description provided for @toolDocumentFactorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Turn Excel rows into personalized PDFs'**
  String get toolDocumentFactorySubtitle;

  /// No description provided for @toolPriceMonitorTitle.
  ///
  /// In en, this message translates to:
  /// **'Price monitor'**
  String get toolPriceMonitorTitle;

  /// No description provided for @toolPriceMonitorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Watch prices in the background and get notified'**
  String get toolPriceMonitorSubtitle;

  /// No description provided for @toolScheduledBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Scheduled backup'**
  String get toolScheduledBackupTitle;

  /// No description provided for @toolScheduledBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Zip a folder on a schedule with a dated archive name'**
  String get toolScheduledBackupSubtitle;

  /// No description provided for @comingSoonBadge.
  ///
  /// In en, this message translates to:
  /// **'Soon'**
  String get comingSoonBadge;

  /// No description provided for @toolComingSoonSemantics.
  ///
  /// In en, this message translates to:
  /// **'{title}, coming soon'**
  String toolComingSoonSemantics(String title);

  /// No description provided for @toolRowSemantics.
  ///
  /// In en, this message translates to:
  /// **'{title}, {subtitle}'**
  String toolRowSemantics(String title, String subtitle);

  /// No description provided for @backToHomeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get backToHomeTooltip;

  /// No description provided for @placeholderHeadline.
  ///
  /// In en, this message translates to:
  /// **'Coming in the next milestone'**
  String get placeholderHeadline;

  /// No description provided for @placeholderMessage.
  ///
  /// In en, this message translates to:
  /// **'{tool} is on the roadmap. The navigation shell is ready; full workflow for {toolId} ships in a later release.'**
  String placeholderMessage(String tool, String toolId);

  /// No description provided for @languageMenuLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageMenuLabel;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// No description provided for @inventoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Barcode inventory'**
  String get inventoryTitle;

  /// No description provided for @inventoryIntro.
  ///
  /// In en, this message translates to:
  /// **'Scan products with a USB or Bluetooth wedge reader, upload one or more barcode images, or enter identifiers manually. Supports QR codes, linear barcodes, and alphanumeric SKUs.'**
  String get inventoryIntro;

  /// No description provided for @inventoryImportCsv.
  ///
  /// In en, this message translates to:
  /// **'Import CSV'**
  String get inventoryImportCsv;

  /// No description provided for @inventoryExportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get inventoryExportCsv;

  /// No description provided for @inventoryManualEntry.
  ///
  /// In en, this message translates to:
  /// **'Manual entry'**
  String get inventoryManualEntry;

  /// No description provided for @inventoryScanFromImages.
  ///
  /// In en, this message translates to:
  /// **'Scan from images'**
  String get inventoryScanFromImages;

  /// No description provided for @inventorySearchStockLabel.
  ///
  /// In en, this message translates to:
  /// **'Search stock'**
  String get inventorySearchStockLabel;

  /// No description provided for @inventorySearchStockHint.
  ///
  /// In en, this message translates to:
  /// **'Name, barcode, notes — typos & accents OK'**
  String get inventorySearchStockHint;

  /// No description provided for @inventoryClearSearchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get inventoryClearSearchTooltip;

  /// No description provided for @inventoryMoreActionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get inventoryMoreActionsTooltip;

  /// No description provided for @inventoryItemActionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Actions for {name}'**
  String inventoryItemActionsTooltip(String name);

  /// No description provided for @inventorySearchMatchCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 match} other{{count} matches}}'**
  String inventorySearchMatchCount(int count);

  /// No description provided for @inventoryDecodingImagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Reading barcodes from images…'**
  String get inventoryDecodingImagesTitle;

  /// No description provided for @inventoryDecodingImagesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can still move the window while this runs.'**
  String get inventoryDecodingImagesSubtitle;

  /// No description provided for @inventoryItemsChip.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String inventoryItemsChip(int count);

  /// No description provided for @inventoryUnitsChip.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 unit on hand} other{{count} units on hand}}'**
  String inventoryUnitsChip(int count);

  /// No description provided for @inventoryOfflineBadge.
  ///
  /// In en, this message translates to:
  /// **'Working offline'**
  String get inventoryOfflineBadge;

  /// No description provided for @inventoryLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading inventory…'**
  String get inventoryLoading;

  /// No description provided for @inventoryLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load inventory'**
  String get inventoryLoadErrorTitle;

  /// No description provided for @inventoryGenericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get inventoryGenericError;

  /// No description provided for @inventoryRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get inventoryRetry;

  /// No description provided for @inventoryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No items yet'**
  String get inventoryEmptyTitle;

  /// No description provided for @inventoryEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Scan a barcode to add your first item.'**
  String get inventoryEmptyMessage;

  /// No description provided for @inventoryNoMatchingItems.
  ///
  /// In en, this message translates to:
  /// **'No matching items'**
  String get inventoryNoMatchingItems;

  /// No description provided for @inventoryImportSkippedBanner.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 row from the last import was skipped or merged} other{{count} rows from the last import were skipped or merged}}'**
  String inventoryImportSkippedBanner(int count);

  /// No description provided for @inventoryDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get inventoryDismiss;

  /// No description provided for @inventoryDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete item?'**
  String get inventoryDeleteTitle;

  /// No description provided for @inventoryDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{name}\" from inventory?'**
  String inventoryDeleteMessage(String name);

  /// No description provided for @inventoryCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get inventoryCancel;

  /// No description provided for @inventoryDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get inventoryDelete;

  /// No description provided for @inventoryImportConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Replace current inventory?'**
  String get inventoryImportConfirmTitle;

  /// No description provided for @inventoryImportConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Importing a CSV replaces ALL current items. This cannot be undone.'**
  String get inventoryImportConfirmMessage;

  /// No description provided for @inventoryImportConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get inventoryImportConfirmAction;

  /// No description provided for @inventoryScanFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Scan barcode'**
  String get inventoryScanFieldLabel;

  /// No description provided for @inventoryScanFieldHint.
  ///
  /// In en, this message translates to:
  /// **'Scan barcode…'**
  String get inventoryScanFieldHint;

  /// No description provided for @inventoryScanFieldSemantics.
  ///
  /// In en, this message translates to:
  /// **'Barcode scan field'**
  String get inventoryScanFieldSemantics;

  /// No description provided for @inventoryItemSemantics.
  ///
  /// In en, this message translates to:
  /// **'{name}, barcode {barcode}, quantity {quantity}'**
  String inventoryItemSemantics(String name, String barcode, int quantity);

  /// No description provided for @inventoryQuantityChip.
  ///
  /// In en, this message translates to:
  /// **'Qty: {quantity}'**
  String inventoryQuantityChip(int quantity);

  /// No description provided for @inventoryEditItem.
  ///
  /// In en, this message translates to:
  /// **'Edit item'**
  String get inventoryEditItem;

  /// No description provided for @inventoryDeleteItem.
  ///
  /// In en, this message translates to:
  /// **'Delete item'**
  String get inventoryDeleteItem;

  /// No description provided for @inventoryRecentScans.
  ///
  /// In en, this message translates to:
  /// **'Recent scans'**
  String get inventoryRecentScans;

  /// No description provided for @inventoryNewItemTitle.
  ///
  /// In en, this message translates to:
  /// **'New item'**
  String get inventoryNewItemTitle;

  /// No description provided for @inventoryNewItemSemantics.
  ///
  /// In en, this message translates to:
  /// **'New item dialog'**
  String get inventoryNewItemSemantics;

  /// No description provided for @inventoryBarcodeIdentifierLabel.
  ///
  /// In en, this message translates to:
  /// **'Barcode / identifier'**
  String get inventoryBarcodeIdentifierLabel;

  /// No description provided for @inventoryItemNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Item name'**
  String get inventoryItemNameLabel;

  /// No description provided for @inventoryErrorEnterName.
  ///
  /// In en, this message translates to:
  /// **'Enter an item name'**
  String get inventoryErrorEnterName;

  /// No description provided for @inventoryErrorInvalidQuantity.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid quantity'**
  String get inventoryErrorInvalidQuantity;

  /// No description provided for @inventoryStartingQuantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Starting quantity'**
  String get inventoryStartingQuantityLabel;

  /// No description provided for @inventoryQuantityHelperNavigation.
  ///
  /// In en, this message translates to:
  /// **'↑/↓ or +/− to adjust · Enter for next · Shift+Enter for previous'**
  String get inventoryQuantityHelperNavigation;

  /// No description provided for @inventoryDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get inventoryDescriptionLabel;

  /// No description provided for @inventoryDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Optional notes (size, location, supplier…)'**
  String get inventoryDescriptionHint;

  /// No description provided for @inventoryAddItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get inventoryAddItem;

  /// No description provided for @inventoryCountQuantityTitle.
  ///
  /// In en, this message translates to:
  /// **'Set counted quantity'**
  String get inventoryCountQuantityTitle;

  /// No description provided for @inventoryIdentifierLine.
  ///
  /// In en, this message translates to:
  /// **'Identifier: {barcode}'**
  String inventoryIdentifierLine(String barcode);

  /// No description provided for @inventoryQuantityOnHandLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity on hand'**
  String get inventoryQuantityOnHandLabel;

  /// No description provided for @inventoryQuantityHelperConfirm.
  ///
  /// In en, this message translates to:
  /// **'↑/↓ or +/− to adjust · Enter to confirm'**
  String get inventoryQuantityHelperConfirm;

  /// No description provided for @inventorySetQuantity.
  ///
  /// In en, this message translates to:
  /// **'Set quantity'**
  String get inventorySetQuantity;

  /// No description provided for @inventorySave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get inventorySave;

  /// No description provided for @inventoryManualEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter identifier manually'**
  String get inventoryManualEntryTitle;

  /// No description provided for @inventoryManualEntryLabel.
  ///
  /// In en, this message translates to:
  /// **'Barcode / SKU / alphanumeric ID'**
  String get inventoryManualEntryLabel;

  /// No description provided for @inventoryManualEntryHint.
  ///
  /// In en, this message translates to:
  /// **'Type or paste an identifier'**
  String get inventoryManualEntryHint;

  /// No description provided for @inventoryErrorEnterBarcode.
  ///
  /// In en, this message translates to:
  /// **'Enter a barcode or identifier'**
  String get inventoryErrorEnterBarcode;

  /// No description provided for @inventorySubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get inventorySubmit;

  /// No description provided for @inventoryToastAdded.
  ///
  /// In en, this message translates to:
  /// **'Added {name}'**
  String inventoryToastAdded(String name);

  /// No description provided for @inventoryToastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {name}: {quantity}'**
  String inventoryToastUpdated(String name, int quantity);

  /// No description provided for @inventoryToastScan.
  ///
  /// In en, this message translates to:
  /// **'{verb} {name}: {quantity}'**
  String inventoryToastScan(String verb, String name, int quantity);

  /// No description provided for @inventoryVerbReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get inventoryVerbReceived;

  /// No description provided for @inventoryVerbShipped.
  ///
  /// In en, this message translates to:
  /// **'Shipped'**
  String get inventoryVerbShipped;

  /// No description provided for @inventoryVerbUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get inventoryVerbUpdated;

  /// No description provided for @inventoryToastDeleted.
  ///
  /// In en, this message translates to:
  /// **'Item deleted'**
  String get inventoryToastDeleted;

  /// No description provided for @inventoryToastExported.
  ///
  /// In en, this message translates to:
  /// **'Exported inventory to {path}'**
  String inventoryToastExported(String path);

  /// No description provided for @inventoryToastImported.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Imported 1 item} other{Imported {count} items}}'**
  String inventoryToastImported(int count);

  /// No description provided for @inventoryImportSkippedPart.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 row skipped} other{{count} rows skipped}}'**
  String inventoryImportSkippedPart(int count);

  /// No description provided for @inventoryImportDuplicatesPart.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 duplicate merged} other{{count} duplicates merged}}'**
  String inventoryImportDuplicatesPart(int count);

  /// No description provided for @inventoryErrorImport.
  ///
  /// In en, this message translates to:
  /// **'Could not import CSV: {error}'**
  String inventoryErrorImport(String error);

  /// No description provided for @inventoryBatchScansProcessed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 scan processed} other{{count} scans processed}}'**
  String inventoryBatchScansProcessed(int count);

  /// No description provided for @inventoryBatchImagesNoCode.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 image with no code found} other{{count} images with no code found}}'**
  String inventoryBatchImagesNoCode(int count);

  /// No description provided for @inventoryBatchNoBarcodes.
  ///
  /// In en, this message translates to:
  /// **'No barcodes found in selected images'**
  String get inventoryBatchNoBarcodes;

  /// No description provided for @inventoryModeReceiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get inventoryModeReceiveLabel;

  /// No description provided for @inventoryModeShipLabel.
  ///
  /// In en, this message translates to:
  /// **'Ship'**
  String get inventoryModeShipLabel;

  /// No description provided for @inventoryModeCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get inventoryModeCountLabel;

  /// No description provided for @inventoryModeReceiveDescription.
  ///
  /// In en, this message translates to:
  /// **'Add 1 to stock on each scan'**
  String get inventoryModeReceiveDescription;

  /// No description provided for @inventoryModeShipDescription.
  ///
  /// In en, this message translates to:
  /// **'Remove 1 from stock on each scan'**
  String get inventoryModeShipDescription;

  /// No description provided for @inventoryModeCountDescription.
  ///
  /// In en, this message translates to:
  /// **'Set exact quantity after scan'**
  String get inventoryModeCountDescription;

  /// No description provided for @inventoryFailureLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load inventory'**
  String get inventoryFailureLoad;

  /// No description provided for @inventoryFailureSave.
  ///
  /// In en, this message translates to:
  /// **'Could not save the scan'**
  String get inventoryFailureSave;

  /// No description provided for @inventoryFailureCreate.
  ///
  /// In en, this message translates to:
  /// **'Could not save the item'**
  String get inventoryFailureCreate;

  /// No description provided for @inventoryFailureDuplicate.
  ///
  /// In en, this message translates to:
  /// **'An item with this barcode already exists'**
  String get inventoryFailureDuplicate;

  /// No description provided for @inventoryFailureInsufficient.
  ///
  /// In en, this message translates to:
  /// **'Not enough stock to ship this quantity'**
  String get inventoryFailureInsufficient;

  /// No description provided for @inventoryFailureDecode.
  ///
  /// In en, this message translates to:
  /// **'No barcode or QR code found in that image'**
  String get inventoryFailureDecode;

  /// No description provided for @inventoryFailureExport.
  ///
  /// In en, this message translates to:
  /// **'Could not export inventory'**
  String get inventoryFailureExport;

  /// No description provided for @inventoryFailureExportEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing to export yet'**
  String get inventoryFailureExportEmpty;

  /// No description provided for @inventoryFailureImport.
  ///
  /// In en, this message translates to:
  /// **'Could not import inventory'**
  String get inventoryFailureImport;

  /// No description provided for @inventoryFailureImportEmpty.
  ///
  /// In en, this message translates to:
  /// **'That CSV file is empty'**
  String get inventoryFailureImportEmpty;

  /// No description provided for @inventoryFailureImportColumns.
  ///
  /// In en, this message translates to:
  /// **'CSV must include barcode, name, and quantity_on_hand columns'**
  String get inventoryFailureImportColumns;

  /// No description provided for @inventoryFailureImportNoRows.
  ///
  /// In en, this message translates to:
  /// **'No valid rows found in CSV'**
  String get inventoryFailureImportNoRows;

  /// No description provided for @inventoryFailureValidationDescription.
  ///
  /// In en, this message translates to:
  /// **'Description is too long'**
  String get inventoryFailureValidationDescription;

  /// No description provided for @inventoryFailureValidationUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown item — create it first or switch to Receive mode'**
  String get inventoryFailureValidationUnknown;

  /// No description provided for @consolidatorTitle.
  ///
  /// In en, this message translates to:
  /// **'Report consolidator'**
  String get consolidatorTitle;

  /// No description provided for @consolidatorHeadline.
  ///
  /// In en, this message translates to:
  /// **'Merge Excel reports'**
  String get consolidatorHeadline;

  /// No description provided for @consolidatorDescription.
  ///
  /// In en, this message translates to:
  /// **'Pick a folder of .xlsx files. The app combines them into one workbook and lists any files that could not be read.'**
  String get consolidatorDescription;

  /// No description provided for @consolidatorOutputFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'Output folder'**
  String get consolidatorOutputFolderTitle;

  /// No description provided for @consolidatorOutputFolderDefault.
  ///
  /// In en, this message translates to:
  /// **'Same as the source folder (default)'**
  String get consolidatorOutputFolderDefault;

  /// No description provided for @consolidatorChooseOutputFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose output folder'**
  String get consolidatorChooseOutputFolder;

  /// No description provided for @consolidatorUseSourceFolder.
  ///
  /// In en, this message translates to:
  /// **'Use source folder'**
  String get consolidatorUseSourceFolder;

  /// No description provided for @consolidatorChooseAndMerge.
  ///
  /// In en, this message translates to:
  /// **'Choose folder and merge'**
  String get consolidatorChooseAndMerge;

  /// No description provided for @consolidatorNoSpreadsheetsTitle.
  ///
  /// In en, this message translates to:
  /// **'No spreadsheets found'**
  String get consolidatorNoSpreadsheetsTitle;

  /// No description provided for @consolidatorNoSpreadsheetsMessage.
  ///
  /// In en, this message translates to:
  /// **'That folder did not contain any .xlsx files. Try a different folder with Excel reports inside.'**
  String get consolidatorNoSpreadsheetsMessage;

  /// No description provided for @consolidatorChooseAnotherFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose another folder'**
  String get consolidatorChooseAnotherFolder;

  /// No description provided for @consolidatorPartialTitle.
  ///
  /// In en, this message translates to:
  /// **'Merged with some failures'**
  String get consolidatorPartialTitle;

  /// No description provided for @consolidatorSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Merge complete'**
  String get consolidatorSuccessTitle;

  /// No description provided for @consolidatorErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Merge could not finish'**
  String get consolidatorErrorTitle;

  /// No description provided for @consolidatorErrorFallback.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while reading the files. Check that the folder is readable and try again.'**
  String get consolidatorErrorFallback;

  /// No description provided for @consolidatorTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get consolidatorTryAgain;

  /// No description provided for @consolidatorMergingProgress.
  ///
  /// In en, this message translates to:
  /// **'Merging spreadsheets… {percent}%'**
  String consolidatorMergingProgress(int percent);

  /// No description provided for @consolidatorPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing merge…'**
  String get consolidatorPreparing;

  /// No description provided for @consolidatorMergeProgressSemantics.
  ///
  /// In en, this message translates to:
  /// **'Merge progress {percent} percent'**
  String consolidatorMergeProgressSemantics(int percent);

  /// No description provided for @consolidatorMergingHint.
  ///
  /// In en, this message translates to:
  /// **'Large folders may take a minute. You can keep this window open.'**
  String get consolidatorMergingHint;

  /// No description provided for @consolidatorSavedAs.
  ///
  /// In en, this message translates to:
  /// **'Saved as {fileName}'**
  String consolidatorSavedAs(String fileName);

  /// No description provided for @consolidatorSavedInOutput.
  ///
  /// In en, this message translates to:
  /// **'Output saved in the chosen output folder.'**
  String get consolidatorSavedInOutput;

  /// No description provided for @consolidatorFailuresTitle.
  ///
  /// In en, this message translates to:
  /// **'Files that need attention'**
  String get consolidatorFailuresTitle;

  /// No description provided for @consolidatorFailuresMessage.
  ///
  /// In en, this message translates to:
  /// **'These files were skipped or could not be read. Fix or remove them and run merge again.'**
  String get consolidatorFailuresMessage;

  /// No description provided for @consolidatorFailureFallback.
  ///
  /// In en, this message translates to:
  /// **'Could not read this workbook'**
  String get consolidatorFailureFallback;

  /// No description provided for @consolidatorFailedFileSemantics.
  ///
  /// In en, this message translates to:
  /// **'Failed file {fileName}'**
  String consolidatorFailedFileSemantics(String fileName);

  /// No description provided for @consolidatorRecentMerges.
  ///
  /// In en, this message translates to:
  /// **'Recent merges'**
  String get consolidatorRecentMerges;

  /// No description provided for @consolidatorHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Completed merges appear here. Up to 20 are kept.'**
  String get consolidatorHistoryEmpty;

  /// No description provided for @consolidatorOpenFileLocation.
  ///
  /// In en, this message translates to:
  /// **'Open file location'**
  String get consolidatorOpenFileLocation;

  /// No description provided for @consolidatorMergedSemantics.
  ///
  /// In en, this message translates to:
  /// **'Merged {fileName} on {time}'**
  String consolidatorMergedSemantics(String fileName, String time);

  /// No description provided for @warningSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warningSemanticLabel;

  /// No description provided for @routerPageNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get routerPageNotFoundTitle;

  /// No description provided for @routerPageNotFoundHeading.
  ///
  /// In en, this message translates to:
  /// **'This page does not exist'**
  String get routerPageNotFoundHeading;

  /// No description provided for @routerPageNotFoundFallback.
  ///
  /// In en, this message translates to:
  /// **'Check the address or return home.'**
  String get routerPageNotFoundFallback;

  /// No description provided for @documentFactoryHeadline.
  ///
  /// In en, this message translates to:
  /// **'Batch personalized PDFs'**
  String get documentFactoryHeadline;

  /// No description provided for @documentFactoryDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose an HTML template with {token} tokens, pick a data sheet, map fields, and generate one PDF per row.'**
  String documentFactoryDescription(String token);

  /// No description provided for @documentFactoryTemplateSection.
  ///
  /// In en, this message translates to:
  /// **'Template'**
  String get documentFactoryTemplateSection;

  /// No description provided for @documentFactoryDataSection.
  ///
  /// In en, this message translates to:
  /// **'Data sheet'**
  String get documentFactoryDataSection;

  /// No description provided for @documentFactoryMappingSection.
  ///
  /// In en, this message translates to:
  /// **'Map fields'**
  String get documentFactoryMappingSection;

  /// No description provided for @documentFactoryOutputSection.
  ///
  /// In en, this message translates to:
  /// **'Output folder'**
  String get documentFactoryOutputSection;

  /// No description provided for @documentFactoryChooseTemplate.
  ///
  /// In en, this message translates to:
  /// **'Choose template'**
  String get documentFactoryChooseTemplate;

  /// No description provided for @documentFactoryChooseDataSheet.
  ///
  /// In en, this message translates to:
  /// **'Choose data sheet'**
  String get documentFactoryChooseDataSheet;

  /// No description provided for @documentFactorySaveMapping.
  ///
  /// In en, this message translates to:
  /// **'Save mapping'**
  String get documentFactorySaveMapping;

  /// No description provided for @documentFactoryChooseOutputFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose output folder'**
  String get documentFactoryChooseOutputFolder;

  /// No description provided for @documentFactoryGenerate.
  ///
  /// In en, this message translates to:
  /// **'Generate PDFs'**
  String get documentFactoryGenerate;

  /// No description provided for @documentFactoryOpenOutputFolder.
  ///
  /// In en, this message translates to:
  /// **'Open output folder'**
  String get documentFactoryOpenOutputFolder;

  /// No description provided for @documentFactoryMappingSaved.
  ///
  /// In en, this message translates to:
  /// **'Mapping saved'**
  String get documentFactoryMappingSaved;

  /// No description provided for @documentFactoryMapAllHint.
  ///
  /// In en, this message translates to:
  /// **'Map all placeholders before generating'**
  String get documentFactoryMapAllHint;

  /// No description provided for @documentFactoryNoTemplate.
  ///
  /// In en, this message translates to:
  /// **'No template selected'**
  String get documentFactoryNoTemplate;

  /// No description provided for @documentFactoryNoDataSheet.
  ///
  /// In en, this message translates to:
  /// **'No data sheet selected'**
  String get documentFactoryNoDataSheet;

  /// No description provided for @documentFactoryNoOutput.
  ///
  /// In en, this message translates to:
  /// **'No output folder selected'**
  String get documentFactoryNoOutput;

  /// No description provided for @documentFactoryMappingEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Select a template and data sheet to map fields'**
  String get documentFactoryMappingEmptyHint;

  /// No description provided for @documentFactoryZeroPlaceholders.
  ///
  /// In en, this message translates to:
  /// **'No placeholders found in this template. Use a template with {token} tokens.'**
  String documentFactoryZeroPlaceholders(String token);

  /// No description provided for @documentFactoryPartialTitle.
  ///
  /// In en, this message translates to:
  /// **'Generated with some errors'**
  String get documentFactoryPartialTitle;

  /// No description provided for @documentFactoryPartialCounts.
  ///
  /// In en, this message translates to:
  /// **'{success} PDFs created, {failed} rows failed'**
  String documentFactoryPartialCounts(int success, int failed);

  /// No description provided for @documentFactorySuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'PDFs generated'**
  String get documentFactorySuccessTitle;

  /// No description provided for @documentFactorySuccessSummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 PDF saved to {folderBasename}} other{{count} PDFs saved to {folderBasename}}}'**
  String documentFactorySuccessSummary(int count, String folderBasename);

  /// No description provided for @documentFactoryErrorBatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Batch failed'**
  String get documentFactoryErrorBatchTitle;

  /// No description provided for @documentFactoryErrorTemplate.
  ///
  /// In en, this message translates to:
  /// **'Could not read the template file. Choose a different file.'**
  String get documentFactoryErrorTemplate;

  /// No description provided for @documentFactoryErrorSheet.
  ///
  /// In en, this message translates to:
  /// **'Could not read the data sheet. Choose a different .xlsx file.'**
  String get documentFactoryErrorSheet;

  /// No description provided for @documentFactoryErrorOutput.
  ///
  /// In en, this message translates to:
  /// **'Cannot write to the output folder. Choose a folder where you have permission to save files.'**
  String get documentFactoryErrorOutput;

  /// No description provided for @documentFactoryErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong during PDF generation.'**
  String get documentFactoryErrorGeneric;

  /// No description provided for @documentFactoryDuplicateHeaders.
  ///
  /// In en, this message translates to:
  /// **'The data sheet has duplicate column headers. Fix the sheet and try again.'**
  String get documentFactoryDuplicateHeaders;

  /// No description provided for @documentFactoryRowRenderFailure.
  ///
  /// In en, this message translates to:
  /// **'Could not create PDF for this row'**
  String get documentFactoryRowRenderFailure;

  /// No description provided for @documentFactoryEmptyRowsSkipped.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 empty row skipped} other{{count} empty rows skipped}}'**
  String documentFactoryEmptyRowsSkipped(int count);

  /// No description provided for @documentFactoryProgress.
  ///
  /// In en, this message translates to:
  /// **'Generating PDFs… {done} of {total}'**
  String documentFactoryProgress(int done, int total);

  /// No description provided for @documentFactoryProgressAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} PDFs generated'**
  String documentFactoryProgressAnnouncement(int done, int total);

  /// No description provided for @documentFactoryInterrupted.
  ///
  /// In en, this message translates to:
  /// **'The last job did not finish. You can start a new batch.'**
  String get documentFactoryInterrupted;

  /// No description provided for @documentFactoryMappingSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save mapping. Try again.'**
  String get documentFactoryMappingSaveError;

  /// No description provided for @documentFactoryFailureRow.
  ///
  /// In en, this message translates to:
  /// **'Row {n}: {message}'**
  String documentFactoryFailureRow(int n, String message);

  /// No description provided for @documentFactoryTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get documentFactoryTryAgain;

  /// No description provided for @documentFactoryLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get documentFactoryLoading;

  /// No description provided for @documentFactoryPlaceholderCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 placeholder} other{{count} placeholders}}'**
  String documentFactoryPlaceholderCount(int count);

  /// No description provided for @documentFactorySheetRowCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 data row} other{{count} data rows}}'**
  String documentFactorySheetRowCount(int count);

  /// No description provided for @documentFactorySheetColumnCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 column} other{{count} columns}}'**
  String documentFactorySheetColumnCount(int count);

  /// No description provided for @documentFactorySelectColumn.
  ///
  /// In en, this message translates to:
  /// **'Select column'**
  String get documentFactorySelectColumn;

  /// No description provided for @documentFactoryColumnFor.
  ///
  /// In en, this message translates to:
  /// **'Column for {placeholder}'**
  String documentFactoryColumnFor(String placeholder);

  /// No description provided for @documentFactoryRowsFailedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 row failed} other{{count} rows failed}}'**
  String documentFactoryRowsFailedCount(int count);

  /// No description provided for @documentFactoryRevealError.
  ///
  /// In en, this message translates to:
  /// **'Could not open the output folder on this desktop.'**
  String get documentFactoryRevealError;

  /// Intro line under the price monitor title
  ///
  /// In en, this message translates to:
  /// **'Track product prices and get notified when one crosses your threshold.'**
  String get priceMonitorIntro;

  /// No description provided for @priceMonitorAddWatch.
  ///
  /// In en, this message translates to:
  /// **'Add watch'**
  String get priceMonitorAddWatch;

  /// No description provided for @priceMonitorLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading watches…'**
  String get priceMonitorLoading;

  /// No description provided for @priceMonitorEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No price watches yet'**
  String get priceMonitorEmptyTitle;

  /// No description provided for @priceMonitorEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add a watch to get notified when a price crosses your threshold.'**
  String get priceMonitorEmptyMessage;

  /// No description provided for @priceMonitorNotFetched.
  ///
  /// In en, this message translates to:
  /// **'Not fetched yet'**
  String get priceMonitorNotFetched;

  /// No description provided for @priceMonitorFetchFailed.
  ///
  /// In en, this message translates to:
  /// **'Fetch failed'**
  String get priceMonitorFetchFailed;

  /// No description provided for @priceMonitorParseFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read price from page'**
  String get priceMonitorParseFailed;

  /// No description provided for @priceMonitorRetryNow.
  ///
  /// In en, this message translates to:
  /// **'Retry now'**
  String get priceMonitorRetryNow;

  /// No description provided for @priceMonitorLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load watches'**
  String get priceMonitorLoadErrorTitle;

  /// No description provided for @priceMonitorLoadErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Try closing and reopening the app.'**
  String get priceMonitorLoadErrorMessage;

  /// No description provided for @priceMonitorTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get priceMonitorTryAgain;

  /// No description provided for @priceMonitorOfflineBadge.
  ///
  /// In en, this message translates to:
  /// **'Offline — price checks paused'**
  String get priceMonitorOfflineBadge;

  /// No description provided for @priceMonitorOfflineSemantics.
  ///
  /// In en, this message translates to:
  /// **'Offline, price checks paused'**
  String get priceMonitorOfflineSemantics;

  /// No description provided for @priceMonitorOfflineChip.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get priceMonitorOfflineChip;

  /// No description provided for @priceMonitorUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String priceMonitorUpdated(String time);

  /// No description provided for @priceMonitorAlertLine.
  ///
  /// In en, this message translates to:
  /// **'Alert {direction} {threshold}'**
  String priceMonitorAlertLine(String direction, String threshold);

  /// No description provided for @priceMonitorAbove.
  ///
  /// In en, this message translates to:
  /// **'Above'**
  String get priceMonitorAbove;

  /// No description provided for @priceMonitorBelow.
  ///
  /// In en, this message translates to:
  /// **'Below'**
  String get priceMonitorBelow;

  /// No description provided for @priceMonitorThresholdError.
  ///
  /// In en, this message translates to:
  /// **'Enter a threshold greater than zero'**
  String get priceMonitorThresholdError;

  /// No description provided for @priceMonitorUrlError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid web address starting with http:// or https://'**
  String get priceMonitorUrlError;

  /// No description provided for @priceMonitorLabelError.
  ///
  /// In en, this message translates to:
  /// **'Enter a label'**
  String get priceMonitorLabelError;

  /// No description provided for @priceMonitorLabelTooLongError.
  ///
  /// In en, this message translates to:
  /// **'Keep the label under 120 characters'**
  String get priceMonitorLabelTooLongError;

  /// No description provided for @priceMonitorDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this watch?'**
  String get priceMonitorDeleteConfirmTitle;

  /// No description provided for @priceMonitorDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'The watch stops being polled and its last-known price is removed.'**
  String get priceMonitorDeleteConfirmMessage;

  /// No description provided for @priceMonitorDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get priceMonitorDelete;

  /// No description provided for @priceMonitorCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get priceMonitorCancel;

  /// No description provided for @priceMonitorSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get priceMonitorSave;

  /// No description provided for @priceMonitorDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard unsaved changes?'**
  String get priceMonitorDiscardTitle;

  /// No description provided for @priceMonitorDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get priceMonitorDiscard;

  /// No description provided for @priceMonitorKeepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get priceMonitorKeepEditing;

  /// No description provided for @priceMonitorAlertTitle.
  ///
  /// In en, this message translates to:
  /// **'Price alert: {label}'**
  String priceMonitorAlertTitle(String label);

  /// No description provided for @priceMonitorAlertBody.
  ///
  /// In en, this message translates to:
  /// **'Price is {price} (threshold {threshold})'**
  String priceMonitorAlertBody(String price, String threshold);

  /// No description provided for @priceMonitorDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get priceMonitorDismiss;

  /// No description provided for @priceMonitorMacNotifyHint.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications in System Settings to get price alerts on the desktop.'**
  String get priceMonitorMacNotifyHint;

  /// No description provided for @priceMonitorEditorTitleNew.
  ///
  /// In en, this message translates to:
  /// **'Add watch'**
  String get priceMonitorEditorTitleNew;

  /// No description provided for @priceMonitorEditorTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit watch'**
  String get priceMonitorEditorTitleEdit;

  /// No description provided for @priceMonitorFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get priceMonitorFieldLabel;

  /// No description provided for @priceMonitorFieldUrl.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get priceMonitorFieldUrl;

  /// No description provided for @priceMonitorFieldThreshold.
  ///
  /// In en, this message translates to:
  /// **'Threshold'**
  String get priceMonitorFieldThreshold;

  /// No description provided for @priceMonitorNotifyWhen.
  ///
  /// In en, this message translates to:
  /// **'Notify when'**
  String get priceMonitorNotifyWhen;

  /// No description provided for @priceMonitorEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get priceMonitorEnabled;

  /// No description provided for @priceMonitorToggleSemantics.
  ///
  /// In en, this message translates to:
  /// **'Enable watch {label}'**
  String priceMonitorToggleSemantics(String label);

  /// No description provided for @priceMonitorRowSemantics.
  ///
  /// In en, this message translates to:
  /// **'{label}, last price {price}, updated {time}, alert {direction} {threshold}, {state}'**
  String priceMonitorRowSemantics(
    String label,
    String price,
    String time,
    String direction,
    String threshold,
    String state,
  );

  /// No description provided for @priceMonitorStateEnabled.
  ///
  /// In en, this message translates to:
  /// **'enabled'**
  String get priceMonitorStateEnabled;

  /// No description provided for @priceMonitorStateDisabled.
  ///
  /// In en, this message translates to:
  /// **'disabled'**
  String get priceMonitorStateDisabled;

  /// No description provided for @priceMonitorEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get priceMonitorEdit;

  /// No description provided for @priceMonitorSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save the watch. Try again.'**
  String get priceMonitorSaveError;

  /// No description provided for @priceMonitorErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get priceMonitorErrorGeneric;

  /// No description provided for @backupLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get backupLoading;

  /// No description provided for @backupSettingsSection.
  ///
  /// In en, this message translates to:
  /// **'Backup settings'**
  String get backupSettingsSection;

  /// No description provided for @backupSourceFolderLabel.
  ///
  /// In en, this message translates to:
  /// **'Source folder'**
  String get backupSourceFolderLabel;

  /// No description provided for @backupDestinationFolderLabel.
  ///
  /// In en, this message translates to:
  /// **'Destination folder'**
  String get backupDestinationFolderLabel;

  /// No description provided for @backupChooseSource.
  ///
  /// In en, this message translates to:
  /// **'Choose source folder'**
  String get backupChooseSource;

  /// No description provided for @backupChooseDestination.
  ///
  /// In en, this message translates to:
  /// **'Choose destination folder'**
  String get backupChooseDestination;

  /// No description provided for @backupNoSourceSelected.
  ///
  /// In en, this message translates to:
  /// **'No source folder selected'**
  String get backupNoSourceSelected;

  /// No description provided for @backupNoDestinationSelected.
  ///
  /// In en, this message translates to:
  /// **'No destination folder selected'**
  String get backupNoDestinationSelected;

  /// No description provided for @backupDailyRunHour.
  ///
  /// In en, this message translates to:
  /// **'Daily run hour'**
  String get backupDailyRunHour;

  /// No description provided for @backupEnableSchedule.
  ///
  /// In en, this message translates to:
  /// **'Enable daily schedule'**
  String get backupEnableSchedule;

  /// No description provided for @backupRunNow.
  ///
  /// In en, this message translates to:
  /// **'Back up now'**
  String get backupRunNow;

  /// No description provided for @backupRunning.
  ///
  /// In en, this message translates to:
  /// **'Creating backup…'**
  String get backupRunning;

  /// No description provided for @backupProgressFiles.
  ///
  /// In en, this message translates to:
  /// **'{processed} of {total} files'**
  String backupProgressFiles(int processed, int total);

  /// No description provided for @backupLastRunSection.
  ///
  /// In en, this message translates to:
  /// **'Last run'**
  String get backupLastRunSection;

  /// No description provided for @backupLastRunSucceeded.
  ///
  /// In en, this message translates to:
  /// **'Last backup: succeeded'**
  String get backupLastRunSucceeded;

  /// No description provided for @backupLastRunFailed.
  ///
  /// In en, this message translates to:
  /// **'Last backup: failed'**
  String get backupLastRunFailed;

  /// No description provided for @backupLastRunUnknown.
  ///
  /// In en, this message translates to:
  /// **'Last backup: unknown'**
  String get backupLastRunUnknown;

  /// No description provided for @backupNoBackupsYet.
  ///
  /// In en, this message translates to:
  /// **'No backups yet'**
  String get backupNoBackupsYet;

  /// No description provided for @backupArchivesSection.
  ///
  /// In en, this message translates to:
  /// **'Recent archives'**
  String get backupArchivesSection;

  /// No description provided for @backupNoArchivesYet.
  ///
  /// In en, this message translates to:
  /// **'No archives yet'**
  String get backupNoArchivesYet;

  /// No description provided for @backupNoArchivesHelper.
  ///
  /// In en, this message translates to:
  /// **'Run a backup to see archives here.'**
  String get backupNoArchivesHelper;

  /// No description provided for @backupComplete.
  ///
  /// In en, this message translates to:
  /// **'Backup complete'**
  String get backupComplete;

  /// No description provided for @backupDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get backupDismiss;

  /// No description provided for @backupOfflineNote.
  ///
  /// In en, this message translates to:
  /// **'Backups use local folders only. No internet required.'**
  String get backupOfflineNote;

  /// No description provided for @backupLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load backup settings'**
  String get backupLoadErrorTitle;

  /// No description provided for @backupLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load backup settings. Try again.'**
  String get backupLoadError;

  /// No description provided for @backupRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get backupRetry;

  /// No description provided for @backupFolderSelectionCancelled.
  ///
  /// In en, this message translates to:
  /// **'Folder selection cancelled.'**
  String get backupFolderSelectionCancelled;

  /// No description provided for @backupShowInFolder.
  ///
  /// In en, this message translates to:
  /// **'Show in file manager'**
  String get backupShowInFolder;

  /// No description provided for @backupArchiveRowSemantics.
  ///
  /// In en, this message translates to:
  /// **'{name}, {date}, {size}'**
  String backupArchiveRowSemantics(String name, String date, String size);

  /// No description provided for @backupErrorSourceMissing.
  ///
  /// In en, this message translates to:
  /// **'Source folder not found. Choose the folder again.'**
  String get backupErrorSourceMissing;

  /// No description provided for @backupErrorDestinationNotWritable.
  ///
  /// In en, this message translates to:
  /// **'Cannot write to the destination folder. Choose a different folder or check permissions.'**
  String get backupErrorDestinationNotWritable;

  /// No description provided for @backupErrorSourceNotReadable.
  ///
  /// In en, this message translates to:
  /// **'Cannot read the source folder. Check permissions.'**
  String get backupErrorSourceNotReadable;

  /// No description provided for @backupErrorDiskFull.
  ///
  /// In en, this message translates to:
  /// **'Not enough space in the destination folder.'**
  String get backupErrorDiskFull;

  /// No description provided for @backupErrorSameFolders.
  ///
  /// In en, this message translates to:
  /// **'Source and destination must be different folders.'**
  String get backupErrorSameFolders;

  /// No description provided for @backupErrorInterrupted.
  ///
  /// In en, this message translates to:
  /// **'Backup was interrupted.'**
  String get backupErrorInterrupted;

  /// No description provided for @backupErrorPathTooLong.
  ///
  /// In en, this message translates to:
  /// **'Path is too long for this system. Choose a shorter destination.'**
  String get backupErrorPathTooLong;

  /// No description provided for @backupErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Backup failed. Try again or check the folders.'**
  String get backupErrorGeneric;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
