/// Single backup job configuration (SPEC §7 — v1 supports exactly one job).
///
/// Persisted per-field on change; no Save button (F1).
class BackupJob {
  const BackupJob({
    this.sourceFolder,
    this.destinationFolder,
    this.dailyRunHour = defaultDailyRunHour,
    this.scheduleEnabled = true,
  });

  /// SPEC §4 F1 — default daily run hour is 2 (02:00 local).
  static const defaultDailyRunHour = 2;

  final String? sourceFolder;
  final String? destinationFolder;

  /// Local hour of day 0–23 for the automatic run.
  final int dailyRunHour;
  final bool scheduleEnabled;

  bool get hasSource => sourceFolder != null && sourceFolder!.isNotEmpty;

  bool get hasDestination =>
      destinationFolder != null && destinationFolder!.isNotEmpty;

  bool get isConfigured => hasSource && hasDestination;

  BackupJob copyWith({
    String? sourceFolder,
    String? destinationFolder,
    int? dailyRunHour,
    bool? scheduleEnabled,
  }) {
    return BackupJob(
      sourceFolder: sourceFolder ?? this.sourceFolder,
      destinationFolder: destinationFolder ?? this.destinationFolder,
      dailyRunHour: dailyRunHour ?? this.dailyRunHour,
      scheduleEnabled: scheduleEnabled ?? this.scheduleEnabled,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'sourceFolder': sourceFolder,
    'destinationFolder': destinationFolder,
    'dailyRunHour': dailyRunHour,
    'scheduleEnabled': scheduleEnabled,
  };

  static BackupJob fromJson(Map<String, dynamic> json) {
    final hour = json['dailyRunHour'];
    return BackupJob(
      sourceFolder: json['sourceFolder'] as String?,
      destinationFolder: json['destinationFolder'] as String?,
      dailyRunHour: hour is int && hour >= 0 && hour <= 23
          ? hour
          : defaultDailyRunHour,
      scheduleEnabled: json['scheduleEnabled'] as bool? ?? true,
    );
  }
}
