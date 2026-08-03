/// Batch job that renders one PDF per data-sheet row.
enum DocumentJobStatus { pending, running, succeeded, partial, failed }

/// Per-row failure surfaced in the failure list (SPEC §7).
class RowFailure {
  const RowFailure({
    required this.rowNumber,
    required this.code,
    required this.message,
  });

  /// 1-based data row number (header row is not counted).
  final int rowNumber;

  /// Stable reason code — see DocumentFactoryFailureCodes.
  final String code;

  /// English technical description for logs; UI uses [code].
  final String message;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'rowNumber': rowNumber,
    'code': code,
    'message': message,
  };

  static RowFailure fromJson(Map<String, dynamic> json) {
    return RowFailure(
      rowNumber: json['rowNumber'] as int,
      code: json['code'] as String,
      message: json['message'] as String,
    );
  }
}

/// Metadata for one batch run. Persisted so an interrupted (`running`) job
/// can be detected on the next app launch (SPEC §4.4).
class DocumentJob {
  const DocumentJob({
    required this.id,
    required this.templatePath,
    required this.dataSheetPath,
    required this.outputDirPath,
    required this.status,
    required this.totalRows,
    required this.startedAt,
    this.doneCount = 0,
    this.failedCount = 0,
    this.skippedCount = 0,
    this.finishedAt,
    this.failures = const <RowFailure>[],
  });

  final String id;
  final String templatePath;
  final String dataSheetPath;
  final String outputDirPath;
  final DocumentJobStatus status;
  final int totalRows;
  final DateTime startedAt;
  final int doneCount;
  final int failedCount;
  final int skippedCount;
  final DateTime? finishedAt;
  final List<RowFailure> failures;

  String get outputDirName {
    final segments = outputDirPath.split(RegExp(r'[/\\]'));
    return segments.isEmpty ? outputDirPath : segments.last;
  }

  DocumentJob copyWith({
    DocumentJobStatus? status,
    int? doneCount,
    int? failedCount,
    int? skippedCount,
    DateTime? finishedAt,
    List<RowFailure>? failures,
  }) {
    return DocumentJob(
      id: id,
      templatePath: templatePath,
      dataSheetPath: dataSheetPath,
      outputDirPath: outputDirPath,
      status: status ?? this.status,
      totalRows: totalRows,
      startedAt: startedAt,
      doneCount: doneCount ?? this.doneCount,
      failedCount: failedCount ?? this.failedCount,
      skippedCount: skippedCount ?? this.skippedCount,
      finishedAt: finishedAt ?? this.finishedAt,
      failures: failures ?? this.failures,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'templatePath': templatePath,
    'dataSheetPath': dataSheetPath,
    'outputDirPath': outputDirPath,
    'status': status.name,
    'totalRows': totalRows,
    'startedAt': startedAt.toIso8601String(),
    'doneCount': doneCount,
    'failedCount': failedCount,
    'skippedCount': skippedCount,
    'finishedAt': finishedAt?.toIso8601String(),
    'failures': failures.map((failure) => failure.toJson()).toList(),
  };

  static DocumentJob fromJson(Map<String, dynamic> json) {
    return DocumentJob(
      id: json['id'] as String,
      templatePath: json['templatePath'] as String,
      dataSheetPath: json['dataSheetPath'] as String,
      outputDirPath: json['outputDirPath'] as String,
      status: DocumentJobStatus.values.byName(json['status'] as String),
      totalRows: json['totalRows'] as int,
      startedAt: DateTime.parse(json['startedAt'] as String),
      doneCount: json['doneCount'] as int? ?? 0,
      failedCount: json['failedCount'] as int? ?? 0,
      skippedCount: json['skippedCount'] as int? ?? 0,
      finishedAt: json['finishedAt'] == null
          ? null
          : DateTime.parse(json['finishedAt'] as String),
      failures: (json['failures'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => RowFailure.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}
