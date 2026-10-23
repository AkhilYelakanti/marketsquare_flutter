import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../session/session_manager.dart';

/// Background isolate handler. Must be a top-level / static function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // System tray shows notification payloads automatically while backgrounded.
  // Nothing extra needed here; tap routing is handled in FcmService.init.
}

/// Port of Kotlin `MarketSquareMessagingService` + `FcmTokenProvider`.
///
/// Defensive by design: if Firebase isn't configured yet (missing
/// google-services.json / GoogleService-Info.plist), every method no-ops so the
/// app still runs — exactly like the native `FcmTokenProvider` never blocking
/// login on push setup.
class FcmService {
  static const channelId = 'marketsquare_default';
  static const channelName = 'MarketSquare Notifications';
  static const _fetchTimeout = Duration(seconds: 5);

  static bool _available = false;
  static final _localNotifications = FlutterLocalNotificationsPlugin();

  /// Called when a notification is tapped (or a data message arrives) with its
  /// `data` map, so the router can deep-link.
  static void Function(Map<String, dynamic> data)? onDeepLink;

  /// Called with every received message's `data` so the app can persist an
  /// inbound message into the local messages table (native: messages are pulled,
  /// but a data payload carrying message fields is inserted directly here).
  static void Function(Map<String, dynamic> data)? onMessageData;

  /// Initializes Firebase + local notifications. Safe to call once at startup.
  static Future<void> init() async {
    try {
      await Firebase.initializeApp();
      _available = true;
    } catch (e) {
      debugPrint('FCM: Firebase not configured, push disabled ($e)');
      _available = false;
      return;
    }

    try {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (resp) {
        final payload = resp.payload;
        if (payload != null) onDeepLink?.call(_decodePayload(payload));
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
      channelId,
      channelName,
      importance: Importance.high,
    ));

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();

    // Foreground messages → persist message data + show a local notification.
    FirebaseMessaging.onMessage.listen((m) {
      onMessageData?.call(m.data);
      final n = m.notification;
      final title = n?.title ?? m.data['title'];
      final body = n?.body ?? m.data['body'];
      if ((title ?? '').isEmpty && (body ?? '').isEmpty) return;
      _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: _encodePayload(m.data),
      );
    });

    // App opened from a background notification tap.
    FirebaseMessaging.onMessageOpenedApp.listen((m) {
      onMessageData?.call(m.data);
      onDeepLink?.call(m.data);
    });

    // App launched cold from a notification tap.
    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      onMessageData?.call(initial.data);
      onDeepLink?.call(initial.data);
    }

    // Refreshed token is cached and sent on the next devicesetup login.
    messaging.onTokenRefresh.listen(_cacheToken);
    } catch (e) {
      debugPrint('FCM: init after Firebase.initializeApp failed ($e)');
    }
  }

  /// Returns the current FCM token or the cached one, never throwing.
  /// Mirrors `FcmTokenProvider.getToken` (5s timeout, cache fallback).
  static Future<String?> getToken() async {
    if (!_available) return _cachedTokenFromPrefs();
    try {
      final token = await FirebaseMessaging.instance.getToken().timeout(
            _fetchTimeout,
            onTimeout: () => null,
          );
      if (token != null) await _cacheToken(token);
      return token ?? await _cachedTokenFromPrefs();
    } catch (_) {
      return _cachedTokenFromPrefs();
    }
  }

  static Future<void> _cacheToken(String token) async {
    final sm = await SessionManager.create();
    await sm.saveFcmToken(token);
  }

  static Future<String?> _cachedTokenFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(SessionManager.fcmTokenKey);
  }

  static String _encodePayload(Map<String, dynamic> data) =>
      data.entries.map((e) => '${e.key}\u0001${e.value}').join('\u0002');

  static Map<String, dynamic> _decodePayload(String payload) {
    final map = <String, dynamic>{};
    for (final pair in payload.split('\u0002')) {
      final i = pair.indexOf('\u0001');
      if (i > 0) map[pair.substring(0, i)] = pair.substring(i + 1);
    }
    return map;
  }
}
