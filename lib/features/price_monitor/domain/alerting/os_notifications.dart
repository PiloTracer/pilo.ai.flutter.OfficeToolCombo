/// Delivery result of an OS notification attempt.
enum OsNotifyOutcome {
  delivered,

  /// The OS rejected the notification (permission denied, DE failure).
  failed,

  /// The platform has no supported notification channel (Windows v1).
  unsupported,
}

/// OS notification channel for threshold cross alerts (SPEC §4.3).
///
/// Any [OsNotifyOutcome] other than [OsNotifyOutcome.delivered] must fall
/// back to the in-app banner within 2 seconds (R10).
abstract class OsNotificationService {
  Future<OsNotifyOutcome> showNotification({
    required String title,
    required String body,
  });
}
