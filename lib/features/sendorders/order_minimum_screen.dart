import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/html_text.dart';
import '../../router/app_routes.dart';
import '../orderentry/order_widgets.dart';
import 'send_orders_controller.dart';

/// Port of native `OrderMinimumScreen`: shows the server "Order Minimum
/// Requirements" message and offers ADD TO ORDER or SEND WITHOUT ADDING.
/// (Native renders the HTML in a WebView; here it is shown as text — see
/// core/html_text.dart.)
class OrderMinimumScreen extends ConsumerWidget {
  final int orderId;
  const OrderMinimumScreen({super.key, this.orderId = -1});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = Theme.of(context).colorScheme.primary;
    final st = ref.watch(sendOrdersControllerProvider);
    final ctrl = ref.read(sendOrdersControllerProvider.notifier);
    final effectiveId = st.omShortfallOrderId != -1 ? st.omShortfallOrderId : orderId;
    final text = stripHtml(st.omShortfallHtml);

    return Scaffold(
      appBar: orderAppBar(subtitle: 'ORDER MINIMUM REQUIREMENTS', height: 80),
      bottomNavigationBar: Container(
        color: primary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: () {
                ctrl.clearShortfall();
                context.go(Routes.orderFilling);
              },
              child: Row(children: [
                _circle(primary, Icons.add),
                const SizedBox(width: 10),
                const Text('ADD TO ORDER',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ]),
            ),
            InkWell(
              onTap: () {
                ctrl.clearShortfall();
                context.push('${Routes.submitOrder}?orderId=$effectiveId');
              },
              child: Row(children: [
                const Text('SEND WITHOUT\nADDING',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(width: 10),
                _circle(primary, Icons.email),
              ]),
            ),
          ],
        ),
      ),
      body: Container(
        color: Colors.white,
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Text(text.isEmpty ? 'No requirements available.' : text,
              style: const TextStyle(fontSize: 14)),
        ),
      ),
    );
  }

  Widget _circle(Color primary, IconData icon) => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
            shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
        child: Icon(icon, color: Colors.white, size: 22),
      );
}
