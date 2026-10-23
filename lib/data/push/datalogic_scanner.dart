import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Hardware-scanner bridge (Datalogic Intent Wedge). Exposes decoded barcodes
/// from the device trigger as a stream, via the native [EventChannel].
///
/// On non-Android platforms (or when Intent Wedge isn't enabled) the stream
/// simply never emits — callers fall back to the camera scanner.
class DatalogicScanner {
  static const _channel = EventChannel('com.ms.marketsquare/datalogic');

  Stream<String> get barcodes {
    if (!Platform.isAndroid) return const Stream<String>.empty();
    return _channel
        .receiveBroadcastStream()
        .map((e) => e?.toString() ?? '')
        .where((s) => s.trim().isNotEmpty);
  }
}

final datalogicScannerProvider = Provider<DatalogicScanner>((ref) => DatalogicScanner());
