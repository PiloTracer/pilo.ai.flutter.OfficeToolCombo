/// Schedule kinds supported per backup job.
enum BackupScheduleKind { hourly, daily, weekly, monthly }

/// When a backup job fires automatically.
///
/// Field usage per kind:
/// - hourly: [everyHours] (one of 1, 2, 3, 4, 6, 8, 12).
/// - daily: [hour] (0–23, local).
/// - weekly: [weekday] (1 = Monday … 7 = Sunday, matching
///   [DateTime.weekday]) + [hour].
/// - monthly: [dayOfMonth] (1–31, clamped to the last day of short months)
///   + [hour].
class BackupSchedule {
  const BackupSchedule._({
    required this.kind,
    this.everyHours = defaultEveryHours,
    this.hour = defaultDailyRunHour,
    this.weekday = DateTime.monday,
    this.dayOfMonth = 1,
  });

  const BackupSchedule.hourly({int everyHours = defaultEveryHours})
    : this._(kind: BackupScheduleKind.hourly, everyHours: everyHours);

  const BackupSchedule.daily({int hour = defaultDailyRunHour})
    : this._(kind: BackupScheduleKind.daily, hour: hour);

  const BackupSchedule.weekly({
    int weekday = DateTime.monday,
    int hour = defaultDailyRunHour,
  }) : this._(kind: BackupScheduleKind.weekly, weekday: weekday, hour: hour);

  const BackupSchedule.monthly({
    int dayOfMonth = 1,
    int hour = defaultDailyRunHour,
  }) : this._(
         kind: BackupScheduleKind.monthly,
         dayOfMonth: dayOfMonth,
         hour: hour,
       );

  /// Default daily run hour is 2 (02:00 local).
  static const defaultDailyRunHour = 2;

  /// Default hourly interval.
  static const defaultEveryHours = 4;

  /// Selectable hourly intervals.
  static const hourlyOptions = <int>[1, 2, 3, 4, 6, 8, 12];

  final BackupScheduleKind kind;
  final int everyHours;
  final int hour;
  final int weekday;
  final int dayOfMonth;

  BackupSchedule copyWith({
    BackupScheduleKind? kind,
    int? everyHours,
    int? hour,
    int? weekday,
    int? dayOfMonth,
  }) {
    return BackupSchedule._(
      kind: kind ?? this.kind,
      everyHours: everyHours ?? this.everyHours,
      hour: hour ?? this.hour,
      weekday: weekday ?? this.weekday,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'kind': kind.name,
    'everyHours': everyHours,
    'hour': hour,
    'weekday': weekday,
    'dayOfMonth': dayOfMonth,
  };

  static BackupSchedule fromJson(Map<String, dynamic> json) {
    final kind =
        BackupScheduleKind.values.asNameMap()[json['kind']] ??
        BackupScheduleKind.daily;
    final hour = json['hour'];
    final everyHours = json['everyHours'];
    final weekday = json['weekday'];
    final dayOfMonth = json['dayOfMonth'];
    return BackupSchedule._(
      kind: kind,
      everyHours: everyHours is int && hourlyOptions.contains(everyHours)
          ? everyHours
          : defaultEveryHours,
      hour: hour is int && hour >= 0 && hour <= 23 ? hour : defaultDailyRunHour,
      weekday: weekday is int && weekday >= 1 && weekday <= 7
          ? weekday
          : DateTime.monday,
      dayOfMonth: dayOfMonth is int && dayOfMonth >= 1 && dayOfMonth <= 31
          ? dayOfMonth
          : 1,
    );
  }
}

/// One labeled backup job: source → destination on a schedule.
class BackupJob {
  const BackupJob({
    required this.id,
    required this.label,
    this.sourceFolder,
    this.destinationFolder,
    this.schedule = const BackupSchedule.daily(),
    this.enabled = true,
  });

  /// Label is required and capped at 120 characters.
  static const maxLabelLength = 120;

  final String id;
  final String label;
  final String? sourceFolder;
  final String? destinationFolder;
  final BackupSchedule schedule;
  final bool enabled;

  bool get hasSource => sourceFolder != null && sourceFolder!.isNotEmpty;

  bool get hasDestination =>
      destinationFolder != null && destinationFolder!.isNotEmpty;

  bool get isConfigured => hasSource && hasDestination;

  /// Trimmed, non-empty, within the length cap.
  static bool isValidLabel(String label) {
    final trimmed = label.trim();
    return trimmed.isNotEmpty && trimmed.length <= maxLabelLength;
  }

  BackupJob copyWith({
    String? id,
    String? label,
    String? sourceFolder,
    String? destinationFolder,
    BackupSchedule? schedule,
    bool? enabled,
  }) {
    return BackupJob(
      id: id ?? this.id,
      label: label ?? this.label,
      sourceFolder: sourceFolder ?? this.sourceFolder,
      destinationFolder: destinationFolder ?? this.destinationFolder,
      schedule: schedule ?? this.schedule,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'label': label,
    'sourceFolder': sourceFolder,
    'destinationFolder': destinationFolder,
    'schedule': schedule.toJson(),
    'enabled': enabled,
  };

  static BackupJob fromJson(Map<String, dynamic> json) {
    return BackupJob(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      sourceFolder: json['sourceFolder'] as String?,
      destinationFolder: json['destinationFolder'] as String?,
      schedule: json['schedule'] is Map<String, dynamic>
          ? BackupSchedule.fromJson(json['schedule'] as Map<String, dynamic>)
          : const BackupSchedule.daily(),
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}
