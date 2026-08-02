/// F0 placeholder for Drift bootstrap.
///
/// Real schema and migrations arrive with the first feature that persists data
/// (barcode inventory / settings). Opening a connection here would invent a
/// schema the foundation has not frozen for F0.
class AppDatabaseStub {
  const AppDatabaseStub();

  Future<void> open() async {
    // Intentionally empty until F0-T storage task wires Drift.
  }
}
