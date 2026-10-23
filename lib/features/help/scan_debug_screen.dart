import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/scanner_sheet.dart';
import '../orderentry/order_widgets.dart';

/// Port of native `ScanDebugScreen`: test the barcode scanner, show results.
class ScanDebugScreen extends StatefulWidget {
  const ScanDebugScreen({super.key});

  @override
  State<ScanDebugScreen> createState() => _State();
}

class _State extends State<ScanDebugScreen> {
  final List<String> _scans = [];

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: orderAppBar(subtitle: 'SCAN DEBUG', height: 60),
      bottomNavigationBar: OrderBottomBar(onBack: () => context.pop()),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: () async {
                final code = await ScannerSheet.scan(context);
                if (code != null) setState(() => _scans.insert(0, code));
              },
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('SCAN'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: primary, foregroundColor: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text('Scanned codes', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: _scans.isEmpty
                  ? const Center(
                      child: Text('No scans yet.', style: TextStyle(color: Colors.grey)))
                  : ListView.separated(
                      itemCount: _scans.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (_, i) => ListTile(
                        dense: true,
                        leading: Text('${_scans.length - i}'),
                        title: Text(_scans[i], style: const TextStyle(fontFamily: 'monospace')),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
