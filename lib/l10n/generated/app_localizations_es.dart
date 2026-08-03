// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'OfficeToolCombo';

  @override
  String get homeTagline =>
      'Cinco herramientas de escritorio para el trabajo diario de oficina, sin terminal y sin ticket de soporte.';

  @override
  String get homeChooseTool => 'Elige una herramienta';

  @override
  String get toolReportConsolidatorTitle => 'Consolidador de informes';

  @override
  String get toolReportConsolidatorSubtitle =>
      'Combina una carpeta de archivos Excel en un solo libro ordenado';

  @override
  String get toolBarcodeInventoryTitle => 'Inventario con códigos de barras';

  @override
  String get toolBarcodeInventorySubtitle =>
      'Escanea productos con un lector USB y controla el stock';

  @override
  String get toolDocumentFactoryTitle => 'Fábrica de documentos';

  @override
  String get toolDocumentFactorySubtitle =>
      'Convierte filas de Excel en PDF personalizados';

  @override
  String get toolPriceMonitorTitle => 'Monitor de precios';

  @override
  String get toolPriceMonitorSubtitle =>
      'Vigila precios en segundo plano y recibe avisos';

  @override
  String get toolScheduledBackupTitle => 'Copia de seguridad programada';

  @override
  String get toolScheduledBackupSubtitle =>
      'Comprime una carpeta según un horario con un nombre de archivo fechado';

  @override
  String get comingSoonBadge => 'Pronto';

  @override
  String toolComingSoonSemantics(String title) {
    return '$title, disponible pronto';
  }

  @override
  String get backToHomeTooltip => 'Volver al inicio';

  @override
  String get placeholderHeadline => 'Disponible en el próximo hito';

  @override
  String placeholderMessage(String tool, String toolId) {
    return '$tool está en la hoja de ruta. La estructura de navegación está lista; el flujo completo de $toolId llegará en una versión posterior.';
  }

  @override
  String get languageMenuLabel => 'Idioma';

  @override
  String get languageSystem => 'Predeterminado del sistema';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Español';

  @override
  String get inventoryTitle => 'Inventario con códigos de barras';

  @override
  String get inventoryIntro =>
      'Escanea productos con un lector USB o Bluetooth, sube una o varias imágenes de códigos de barras o introduce identificadores manualmente. Compatible con códigos QR, códigos de barras lineales y SKU alfanuméricos.';

  @override
  String get inventoryImportCsv => 'Importar CSV';

  @override
  String get inventoryExportCsv => 'Exportar CSV';

  @override
  String get inventoryManualEntry => 'Entrada manual';

  @override
  String get inventoryScanFromImages => 'Escanear desde imágenes';

  @override
  String get inventorySearchStockLabel => 'Buscar en el stock';

  @override
  String get inventorySearchStockHint =>
      'Nombre, código, notas: se admiten erratas y acentos';

  @override
  String get inventoryClearSearchTooltip => 'Borrar búsqueda';

  @override
  String inventorySearchMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count coincidencias',
      one: '1 coincidencia',
    );
    return '$_temp0';
  }

  @override
  String get inventoryDecodingImagesTitle =>
      'Leyendo códigos de barras de las imágenes…';

  @override
  String get inventoryDecodingImagesSubtitle =>
      'Puedes seguir moviendo la ventana mientras se ejecuta.';

  @override
  String inventoryItemsChip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count artículos',
      one: '1 artículo',
    );
    return '$_temp0';
  }

  @override
  String inventoryUnitsChip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unidades en stock',
      one: '1 unidad en stock',
    );
    return '$_temp0';
  }

  @override
  String get inventoryOfflineBadge => 'Trabajando sin conexión';

  @override
  String get inventoryLoading => 'Cargando inventario…';

  @override
  String get inventoryLoadErrorTitle => 'No se pudo cargar el inventario';

  @override
  String get inventoryGenericError => 'Algo salió mal';

  @override
  String get inventoryRetry => 'Reintentar';

  @override
  String get inventoryEmptyTitle => 'Aún no hay artículos';

  @override
  String get inventoryEmptyMessage =>
      'Escanea un código de barras para añadir tu primer artículo.';

  @override
  String get inventoryNoMatchingItems => 'No hay artículos que coincidan';

  @override
  String inventoryImportSkippedBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filas de la última importación se omitieron o combinaron',
      one: '1 fila de la última importación se omitió o combinó',
    );
    return '$_temp0';
  }

  @override
  String get inventoryDismiss => 'Descartar';

  @override
  String get inventoryDeleteTitle => '¿Eliminar artículo?';

  @override
  String inventoryDeleteMessage(String name) {
    return '¿Quitar «$name» del inventario?';
  }

  @override
  String get inventoryCancel => 'Cancelar';

  @override
  String get inventoryDelete => 'Eliminar';

  @override
  String get inventoryImportConfirmTitle => '¿Reemplazar el inventario actual?';

  @override
  String get inventoryImportConfirmMessage =>
      'Al importar un CSV se reemplazan TODOS los artículos actuales. Esta acción no se puede deshacer.';

  @override
  String get inventoryImportConfirmAction => 'Importar';

  @override
  String get inventoryScanFieldLabel => 'Escanear código de barras';

  @override
  String get inventoryScanFieldHint => 'Escanea un código de barras…';

  @override
  String get inventoryScanFieldSemantics =>
      'Campo de escaneo de códigos de barras';

  @override
  String inventoryItemSemantics(String name, String barcode, int quantity) {
    return '$name, código de barras $barcode, cantidad $quantity';
  }

  @override
  String inventoryQuantityChip(int quantity) {
    return 'Cant.: $quantity';
  }

  @override
  String get inventoryEditItem => 'Editar artículo';

  @override
  String get inventoryDeleteItem => 'Eliminar artículo';

  @override
  String get inventoryRecentScans => 'Escaneos recientes';

  @override
  String get inventoryNewItemTitle => 'Nuevo artículo';

  @override
  String get inventoryNewItemSemantics => 'Diálogo de nuevo artículo';

  @override
  String get inventoryBarcodeIdentifierLabel =>
      'Código de barras / identificador';

  @override
  String get inventoryItemNameLabel => 'Nombre del artículo';

  @override
  String get inventoryErrorEnterName => 'Introduce un nombre de artículo';

  @override
  String get inventoryErrorInvalidQuantity => 'Introduce una cantidad válida';

  @override
  String get inventoryStartingQuantityLabel => 'Cantidad inicial';

  @override
  String get inventoryQuantityHelperNavigation =>
      '↑/↓ o +/− para ajustar · Intro para siguiente · Mayús+Intro para anterior';

  @override
  String get inventoryDescriptionLabel => 'Descripción';

  @override
  String get inventoryDescriptionHint =>
      'Notas opcionales (tamaño, ubicación, proveedor…)';

  @override
  String get inventoryAddItem => 'Añadir artículo';

  @override
  String get inventoryCountQuantityTitle => 'Establecer cantidad contada';

  @override
  String inventoryIdentifierLine(String barcode) {
    return 'Identificador: $barcode';
  }

  @override
  String get inventoryQuantityOnHandLabel => 'Cantidad en stock';

  @override
  String get inventoryQuantityHelperConfirm =>
      '↑/↓ o +/− para ajustar · Intro para confirmar';

  @override
  String get inventorySetQuantity => 'Establecer cantidad';

  @override
  String get inventorySave => 'Guardar';

  @override
  String get inventoryManualEntryTitle =>
      'Introducir identificador manualmente';

  @override
  String get inventoryManualEntryLabel =>
      'Código de barras / SKU / ID alfanumérico';

  @override
  String get inventoryManualEntryHint => 'Escribe o pega un identificador';

  @override
  String get inventoryErrorEnterBarcode =>
      'Introduce un código de barras o identificador';

  @override
  String get inventorySubmit => 'Enviar';

  @override
  String inventoryToastAdded(String name) {
    return 'Añadido $name';
  }

  @override
  String inventoryToastUpdated(String name, int quantity) {
    return 'Actualizado $name: $quantity';
  }

  @override
  String inventoryToastScan(String verb, String name, int quantity) {
    return '$verb $name: $quantity';
  }

  @override
  String get inventoryVerbReceived => 'Recibido';

  @override
  String get inventoryVerbShipped => 'Enviado';

  @override
  String get inventoryVerbUpdated => 'Actualizado';

  @override
  String get inventoryToastDeleted => 'Artículo eliminado';

  @override
  String inventoryToastExported(String path) {
    return 'Inventario exportado a $path';
  }

  @override
  String inventoryToastImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count artículos importados',
      one: '1 artículo importado',
    );
    return '$_temp0';
  }

  @override
  String inventoryImportSkippedPart(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filas omitidas',
      one: '1 fila omitida',
    );
    return '$_temp0';
  }

  @override
  String inventoryImportDuplicatesPart(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count duplicados combinados',
      one: '1 duplicado combinado',
    );
    return '$_temp0';
  }

  @override
  String inventoryErrorImport(String error) {
    return 'No se pudo importar el CSV: $error';
  }

  @override
  String inventoryBatchScansProcessed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count escaneos procesados',
      one: '1 escaneo procesado',
    );
    return '$_temp0';
  }

  @override
  String inventoryBatchImagesNoCode(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count imágenes sin código',
      one: '1 imagen sin código',
    );
    return '$_temp0';
  }

  @override
  String get inventoryBatchNoBarcodes =>
      'No se encontraron códigos de barras en las imágenes seleccionadas';

  @override
  String get inventoryModeReceiveLabel => 'Recibir';

  @override
  String get inventoryModeShipLabel => 'Enviar';

  @override
  String get inventoryModeCountLabel => 'Contar';

  @override
  String get inventoryModeReceiveDescription =>
      'Suma 1 al stock con cada escaneo';

  @override
  String get inventoryModeShipDescription =>
      'Resta 1 del stock con cada escaneo';

  @override
  String get inventoryModeCountDescription =>
      'Establece la cantidad exacta tras el escaneo';

  @override
  String get inventoryFailureLoad => 'No se pudo cargar el inventario';

  @override
  String get inventoryFailureSave => 'No se pudo guardar el escaneo';

  @override
  String get inventoryFailureCreate => 'No se pudo guardar el artículo';

  @override
  String get inventoryFailureDuplicate =>
      'Ya existe un artículo con este código de barras';

  @override
  String get inventoryFailureInsufficient =>
      'No hay stock suficiente para enviar esta cantidad';

  @override
  String get inventoryFailureDecode =>
      'No se encontró ningún código de barras o QR en esa imagen';

  @override
  String get inventoryFailureExport => 'No se pudo exportar el inventario';

  @override
  String get inventoryFailureExportEmpty => 'Aún no hay nada que exportar';

  @override
  String get inventoryFailureImport => 'No se pudo importar el inventario';

  @override
  String get inventoryFailureImportEmpty => 'Ese archivo CSV está vacío';

  @override
  String get inventoryFailureImportColumns =>
      'El CSV debe incluir las columnas barcode, name y quantity_on_hand';

  @override
  String get inventoryFailureImportNoRows =>
      'No se encontraron filas válidas en el CSV';

  @override
  String get inventoryFailureValidationDescription =>
      'La descripción es demasiado larga';

  @override
  String get inventoryFailureValidationUnknown =>
      'Artículo desconocido: créalo primero o cambia al modo Recibir';

  @override
  String get consolidatorTitle => 'Consolidador de informes';

  @override
  String get consolidatorHeadline => 'Combina informes de Excel';

  @override
  String get consolidatorDescription =>
      'Elige una carpeta de archivos .xlsx. La aplicación los combina en un solo libro y lista los archivos que no se pudieron leer.';

  @override
  String get consolidatorOutputFolderTitle => 'Carpeta de salida';

  @override
  String get consolidatorOutputFolderDefault =>
      'Igual que la carpeta de origen (predeterminado)';

  @override
  String get consolidatorChooseOutputFolder => 'Elegir carpeta de salida';

  @override
  String get consolidatorUseSourceFolder => 'Usar carpeta de origen';

  @override
  String get consolidatorChooseAndMerge => 'Elegir carpeta y combinar';

  @override
  String get consolidatorNoSpreadsheetsTitle =>
      'No se encontraron hojas de cálculo';

  @override
  String get consolidatorNoSpreadsheetsMessage =>
      'Esa carpeta no contenía archivos .xlsx. Prueba con otra carpeta que tenga informes de Excel.';

  @override
  String get consolidatorChooseAnotherFolder => 'Elegir otra carpeta';

  @override
  String get consolidatorPartialTitle => 'Combinado con algunos errores';

  @override
  String get consolidatorSuccessTitle => 'Combinación completada';

  @override
  String get consolidatorErrorTitle => 'La combinación no pudo completarse';

  @override
  String get consolidatorErrorFallback =>
      'Algo salió mal al leer los archivos. Comprueba que la carpeta sea legible e inténtalo de nuevo.';

  @override
  String get consolidatorTryAgain => 'Intentar de nuevo';

  @override
  String consolidatorMergingProgress(int percent) {
    return 'Combinando hojas de cálculo… $percent %';
  }

  @override
  String get consolidatorPreparing => 'Preparando la combinación…';

  @override
  String get consolidatorMergingHint =>
      'Las carpetas grandes pueden tardar un minuto. Puedes dejar esta ventana abierta.';

  @override
  String consolidatorSavedAs(String fileName) {
    return 'Guardado como $fileName';
  }

  @override
  String get consolidatorSavedInOutput =>
      'Resultado guardado en la carpeta de salida elegida.';

  @override
  String get consolidatorFailuresTitle => 'Archivos que necesitan atención';

  @override
  String get consolidatorFailuresMessage =>
      'Estos archivos se omitieron o no se pudieron leer. Corrígelos o elimínalos y vuelve a ejecutar la combinación.';

  @override
  String get consolidatorFailureFallback => 'No se pudo leer este libro';

  @override
  String consolidatorFailedFileSemantics(String fileName) {
    return 'Archivo con error $fileName';
  }

  @override
  String get consolidatorRecentMerges => 'Combinaciones recientes';

  @override
  String get consolidatorHistoryEmpty =>
      'Las combinaciones completadas aparecen aquí. Se conservan hasta 20.';

  @override
  String get consolidatorOpenFileLocation => 'Abrir ubicación del archivo';

  @override
  String consolidatorMergedSemantics(String fileName, String time) {
    return '$fileName combinado el $time';
  }

  @override
  String get warningSemanticLabel => 'Aviso';
}
