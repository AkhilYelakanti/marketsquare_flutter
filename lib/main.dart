import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/push/fcm_service.dart';
import 'data/session/session_manager.dart';
import 'data/session/session_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // SharedPreferences-backed session (replaces native SessionManager).
  final session = await SessionManager.create();

  // Show the UI first — never block the first frame on push setup.
  runApp(
    ProviderScope(
      overrides: [
        sessionManagerProvider.overrideWithValue(session),
      ],
      child: const MarketSquareApp(),
    ),
  );

  // Firebase Cloud Messaging, after the UI is up. Fully defensive: any failure
  // (no Play Services, config issue, plugin error) must not affect the app.
  FcmService.init();
}
