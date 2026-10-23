import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

const _deviceChannel = MethodChannel('com.ms.marketsquare/device');

/// Device id — native parity.
///
/// Android: `Settings.Secure.ANDROID_ID` (the id the native app registered with
/// the backend, e.g. `69431e96a7be4fd3`). device_info_plus's `androidInfo.id`
/// is `Build.ID` (e.g. `1.07.15.20191227`) — a different value that breaks
/// device-setup matching — so we read ANDROID_ID over a platform channel and
/// only fall back to `Build.ID` if the channel is unavailable.
/// iOS: `identifierForVendor`.
Future<String> deviceId() async {
  if (Platform.isAndroid) {
    try {
      final id = await _deviceChannel.invokeMethod<String>('getAndroidId');
      if (id != null && id.isNotEmpty) return id;
    } catch (_) {
      // Channel not registered (e.g. background isolate) — fall through.
    }
    return (await DeviceInfoPlugin().androidInfo).id;
  }
  if (Platform.isIOS) {
    return (await DeviceInfoPlugin().iosInfo).identifierForVendor ?? 'unknown';
  }
  return 'unknown';
}

/// App version (versionId sent to the backend).
Future<String> versionId() async => (await PackageInfo.fromPlatform()).version;
