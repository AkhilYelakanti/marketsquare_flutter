import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/push/datalogic_scanner.dart';

/// Subscribes to the hardware scanner while mounted and invokes [onScan] for
/// each decoded barcode. Renders nothing (drop it into a screen's widget tree).
class HardwareScanListener extends ConsumerStatefulWidget {
  final void Function(String code) onScan;
  const HardwareScanListener({super.key, required this.onScan});

  @override
  ConsumerState<HardwareScanListener> createState() => _State();
}

class _State extends ConsumerState<HardwareScanListener> {
  StreamSubscription<String>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = ref.read(datalogicScannerProvider).barcodes.listen((code) {
      if (mounted) widget.onScan(code);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
