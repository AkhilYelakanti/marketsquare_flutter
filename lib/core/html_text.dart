/// Minimal HTML → plain text. The native app renders server HTML (order minimum
/// requirements, submit response) in a WebView; this strips tags for display
/// until a webview dependency is added. Good enough for the text-only payloads
/// these endpoints return.
String stripHtml(String html) {
  if (html.isEmpty) return '';
  var s = html
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</(p|div|tr|li|h[1-6])>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"');
  s = s.split('\n').map((l) => l.trim()).join('\n');
  return s.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
}
