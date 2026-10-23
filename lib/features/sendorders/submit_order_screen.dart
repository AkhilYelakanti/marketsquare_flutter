import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/html_text.dart';
import '../../data/db/pending_order.dart';
import '../../router/app_routes.dart';
import '../orderentry/order_widgets.dart';
import 'submit_controller.dart';

/// Port of native `SubmitOrderScreen`: submits on entry, shows a spinner while
/// sending, then the success/failure receipt. BACK returns to the dashboard.
class SubmitOrderScreen extends ConsumerStatefulWidget {
  final int orderId;
  const SubmitOrderScreen({super.key, this.orderId = -1});

  @override
  ConsumerState<SubmitOrderScreen> createState() => _State();
}

class _State extends ConsumerState<SubmitOrderScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(submitControllerProvider.notifier).submit(widget.orderId));
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final st = ref.watch(submitControllerProvider);
    final result = st.phase == SubmitPhase.result;

    return Scaffold(
      appBar: orderAppBar(
          subtitle: result ? 'ORDER RESPONSE' : 'SENDING ORDER', height: 60),
      body: result ? _result(context, st, primary) : _sending(st, primary),
    );
  }

  Widget _sending(SubmitState st, Color primary) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (st.order != null) _summary(st.order!, primary),
            const SizedBox(height: 48),
            CircularProgressIndicator(color: primary),
            const SizedBox(height: 24),
            const Text('Sending order...',
                style: TextStyle(fontSize: 16, color: Colors.black54)),
          ],
        ),
      );

  Widget _result(BuildContext context, SubmitState st, Color primary) {
    final ok = st.isSuccess;
    final body = ok ? (st.receipt ?? '') : (st.error ?? '');
    final extra = stripHtml(st.responseHtml);
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (st.order != null) ...[
                _summary(st.order!, primary),
                const SizedBox(height: 12),
              ],
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: ok ? const Color(0xFFF1F8E9) : const Color(0xFFFFF3E0),
                  border: Border.all(
                      color: ok ? const Color(0xFFA5D6A7) : const Color(0xFFFFCC80)),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(ok ? Icons.check_circle : Icons.error_outline,
                          color: ok ? const Color(0xFF2E7D32) : const Color(0xFFE65100)),
                      const SizedBox(width: 8),
                      Text(ok ? 'Send Successful' : 'Submission Failed',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color:
                                  ok ? const Color(0xFF2E7D32) : const Color(0xFFE65100))),
                    ]),
                    if (body.isNotEmpty) ...[
                      const Divider(),
                      Text(body,
                          style: const TextStyle(
                              fontSize: 13,
                              fontFamily: 'monospace',
                              color: Color(0xFF333333))),
                    ],
                    if (extra.isNotEmpty) ...[
                      const Divider(),
                      Text(extra, style: const TextStyle(fontSize: 13)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          color: primary,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: InkWell(
            onTap: () => context.go(Routes.dashboard),
            child: Row(children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2)),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 8),
              const Text('BACK',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _summary(PendingOrder o, Color primary) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          border: Border.all(color: const Color(0xFFDDDDDD)),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(o.orderType,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14, color: primary)),
                Text('Partition: ${o.partition}',
                    style: const TextStyle(fontSize: 13, color: Colors.black54)),
              ],
            ),
            const SizedBox(height: 4),
            Text('Items: ${o.itemCount}   Qty: ${o.totalQty}   Value: \$${o.totalValue}',
                style: const TextStyle(fontSize: 12, color: Colors.black87)),
            if (o.poNumber.isNotEmpty)
              Text('PO: ${o.poNumber}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      );
}
