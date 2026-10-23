import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'data/push/fcm_service.dart';
import 'data/push/push_navigator.dart';
import 'data/session/session_providers.dart';
import 'features/messages/messages_controller.dart';
import 'router/app_router.dart';

class MarketSquareApp extends ConsumerStatefulWidget {
  const MarketSquareApp({super.key});

  @override
  ConsumerState<MarketSquareApp> createState() => _MarketSquareAppState();
}

class _MarketSquareAppState extends ConsumerState<MarketSquareApp> {
  final GoRouter _router = createRouter();

  @override
  void initState() {
    super.initState();
    // Route notification taps/data into the push navigator.
    FcmService.onDeepLink = (data) {
      ref.read(pushNavigatorProvider.notifier).handleMessageData(data);
    };
    // Persist inbound message payloads into the local messages table.
    FcmService.onMessageData = (data) {
      ref.read(messagesControllerProvider.notifier).ingestPushMessage(data);
      ref.invalidate(messagesUnreadProvider);
    };
  }

  @override
  Widget build(BuildContext context) {
    final brandColor = ref.watch(brandColorProvider);

    // Deep-link: once a pending push route exists and the user is past the
    // pre-auth screens, navigate there (native NavGraph parity).
    ref.listen<String?>(pushNavigatorProvider, (_, pending) {
      if (pending == null) return;
      final current = _router.routeInformationProvider.value.uri.path;
      if (PushNavigator.preAuthRoutes.contains(current)) return;
      ref.read(pushNavigatorProvider.notifier).consume();
      _router.go(pending);
    });

    return MaterialApp.router(
      title: 'MS Ordering',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(brandColor),
      routerConfig: _router,
    );
  }
}
