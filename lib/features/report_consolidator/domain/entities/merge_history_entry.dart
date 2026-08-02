import 'package:equatable/equatable.dart';

/// One completed consolidator merge stored for the recent-history panel.
class MergeHistoryEntry extends Equatable {
  const MergeHistoryEntry({
    required this.outputPath,
    required this.fileName,
    required this.sourceFolderPath,
    required this.mergedAt,
    required this.status,
  });

  factory MergeHistoryEntry.fromJson(Map<String, dynamic> json) {
    return MergeHistoryEntry(
      outputPath: json['outputPath'] as String,
      fileName: json['fileName'] as String,
      sourceFolderPath: json['sourceFolderPath'] as String,
      mergedAt: DateTime.parse(json['mergedAt'] as String).toLocal(),
      status: json['status'] as String,
    );
  }

  final String outputPath;
  final String fileName;
  final String sourceFolderPath;
  final DateTime mergedAt;
  final String status;

  Map<String, dynamic> toJson() {
    return {
      'outputPath': outputPath,
      'fileName': fileName,
      'sourceFolderPath': sourceFolderPath,
      'mergedAt': mergedAt.toUtc().toIso8601String(),
      'status': status,
    };
  }

  @override
  List<Object?> get props => [
    outputPath,
    fileName,
    sourceFolderPath,
    mergedAt,
    status,
  ];
}
