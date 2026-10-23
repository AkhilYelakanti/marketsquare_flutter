import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/network/api_client.dart';
import '../repository/login_repository.dart';
import 'session_manager.dart';

/// Overridden in main() after SharedPreferences is ready.
final sessionManagerProvider = Provider<SessionManager>(
  (ref) => throw UnimplementedError('sessionManagerProvider must be overridden'),
);

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final loginRepositoryProvider = Provider<LoginRepository>(
  (ref) => LoginRepository(ref.watch(apiClientProvider)),
);

/// Current brand primary color. Defaults to MsRed; updated from the login
/// response (brandBackgroundTheme hex). Mirrors `parseBrandColor` in Theme.kt.
final brandColorProvider =
    NotifierProvider<BrandColorNotifier, Color>(BrandColorNotifier.new);

class BrandColorNotifier extends Notifier<Color> {
  @override
  Color build() {
    final hex = ref.read(sessionManagerProvider).getBrandBackgroundColor();
    return parseBrandColor(hex) ?? const Color(AppConstants.msRedArgb);
  }

  void setFromHex(String? hex) {
    state = parseBrandColor(hex) ?? const Color(AppConstants.msRedArgb);
  }
}

/// Parses a `#RRGGBB`, `RRGGBB`, or `AARRGGBB` hex string to a Color.
/// Returns null when unparseable (caller falls back to the default).
Color? parseBrandColor(String? hex) {
  final raw = (hex ?? '').trim();
  if (raw.isEmpty) return null;
  final cleaned = raw.startsWith('#') ? raw.substring(1) : raw;
  int? value;
  if (cleaned.length == 6) {
    final rgb = int.tryParse(cleaned, radix: 16);
    if (rgb != null) value = 0xFF000000 | rgb;
  } else if (cleaned.length == 8) {
    value = int.tryParse(cleaned, radix: 16);
  }
  return value == null ? null : Color(value);
}
