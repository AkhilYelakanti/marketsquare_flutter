import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../orderentry/order_widgets.dart';
import 'invoices_controller.dart';

/// Port of native `InvoicePdfScreen`: fetch an invoice PDF by number. The bytes
/// are saved locally; in-app PDF rendering needs a viewer plugin (follow-up).
class InvoicePdfScreen extends ConsumerStatefulWidget {
  const InvoicePdfScreen({super.key});

  @override
  ConsumerState<InvoicePdfScreen> createState() => _State();
}

class _State extends ConsumerState<InvoicePdfScreen> {
  final _ctl = TextEditingController();

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final st = ref.watch(invoicesControllerProvider);
    final ctrl = ref.read(invoicesControllerProvider.notifier);

    return Scaffold(
      appBar: orderAppBar(subtitle: 'INVOICE PDF', height: 60),
      bottomNavigationBar: OrderBottomBar(onBack: () => context.pop()),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _ctl,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Invoice #',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: st.loadingPdf || _ctl.text.trim().isEmpty
                  ? null
                  : () => ctrl.fetchPdf(_ctl.text.trim()),
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('FETCH PDF'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: primary, foregroundColor: Colors.white),
            ),
            const SizedBox(height: 16),
            if (st.loadingPdf) const Center(child: CircularProgressIndicator()),
            if (st.pdfStatus.isNotEmpty)
              Text(st.pdfStatus, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
