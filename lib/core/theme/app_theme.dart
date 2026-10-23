import 'package:flutter/material.dart';

import '../constants.dart';

/// Native palette (Color.kt).
const msRed = Color(AppConstants.msRedArgb); // 0xFFDB2031
const redGrey = Color(0xFF757575);
const redPink = Color(0xFFC2185B);

/// Builds the app theme from the current brand primary color.
/// Light scheme only — the native app forces light mode
/// (AppCompatDelegate.MODE_NIGHT_NO).
ThemeData buildAppTheme(Color brandPrimary) {
  final scheme = ColorScheme.fromSeed(
    seedColor: brandPrimary,
    primary: brandPrimary,
    secondary: redGrey,
    tertiary: redPink,
    brightness: Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: AppBarTheme(
      backgroundColor: brandPrimary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
  );
}
