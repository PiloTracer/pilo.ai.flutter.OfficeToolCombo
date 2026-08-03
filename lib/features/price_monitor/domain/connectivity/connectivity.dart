/// Connectivity probe for the price monitor (SPEC §10 — offline pauses
/// polling; other tools are unaffected). Feature-local and injectable so
/// tests control online state.
abstract class ConnectivityService {
  Future<bool> isOnline();
}
