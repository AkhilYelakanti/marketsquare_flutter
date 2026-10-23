/// In-memory REST call log shown on the Debug screen (port of the native
/// FileLogger's API trace). Captures the request URL/body and the response body
/// for JSON/text calls. Binary file downloads (item file, inventory) are logged
/// by their callers as a short note, never the payload.
class ApiLogEntry {
  final DateTime time;
  final String route;
  final String body;
  final String resp;
  const ApiLogEntry(this.time, this.route, this.body, this.resp);
}

class ApiLog {
  ApiLog._();

  /// When false, new calls are not recorded (toggled from the Debug screen).
  static bool enabled = true;

  static const _max = 120;
  static const _maxRespChars = 6000;
  static final List<ApiLogEntry> _entries = [];

  static List<ApiLogEntry> get entries => List.unmodifiable(_entries);

  static void add(String route, String body, String resp) {
    if (!enabled) return;
    final trimmed = resp.length > _maxRespChars
        ? '${resp.substring(0, _maxRespChars)}…(${resp.length} chars)'
        : resp;
    _entries.add(ApiLogEntry(DateTime.now(), route, body, trimmed));
    if (_entries.length > _max) _entries.removeAt(0);
  }

  static void clear() => _entries.clear();
}
