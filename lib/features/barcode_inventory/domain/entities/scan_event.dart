import 'package:freezed_annotation/freezed_annotation.dart';

part 'scan_event.freezed.dart';

@freezed
abstract class ScanEvent with _$ScanEvent {
  const factory ScanEvent({
    required int id,
    required String barcode,
    String? itemId,
    required DateTime scannedAt,
    required int delta,
  }) = _ScanEvent;
}

enum ScanMode { receive, ship, count }

extension ScanModeX on ScanMode {
  String get label => switch (this) {
    ScanMode.receive => 'Receive',
    ScanMode.ship => 'Ship',
    ScanMode.count => 'Count',
  };

  String get description => switch (this) {
    ScanMode.receive => 'Add 1 to stock on each scan',
    ScanMode.ship => 'Remove 1 from stock on each scan',
    ScanMode.count => 'Set exact quantity after scan',
  };
}
