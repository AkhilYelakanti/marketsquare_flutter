import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Barcode scanner (replaces CameraX + MLKit). Opens as a full-screen modal and
/// returns the first decoded barcode string, or null if dismissed.
///
/// Usage: `final code = await ScannerSheet.scan(context);`
class ScannerSheet extends StatefulWidget {
  const ScannerSheet({super.key});

  static Future<String?> scan(BuildContext context) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ScannerSheet(), fullscreenDialog: true),
    );
  }

  @override
  State<ScannerSheet> createState() => _ScannerSheetState();
}

class _ScannerSheetState extends State<ScannerSheet> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final code = capture.barcodes
        .map((b) => b.rawValue)
        .firstWhere((v) => v != null && v.isNotEmpty, orElse: () => null);
    if (code == null) return;
    _handled = true;
    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SCAN BARCODE')),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          // Simple reticle overlay.
          Container(
            width: 260,
            height: 140,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }
}
