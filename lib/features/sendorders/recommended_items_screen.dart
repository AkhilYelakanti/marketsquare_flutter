import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/order_models.dart';
import '../../router/app_routes.dart';
import '../orderentry/order_widgets.dart';
import 'send_orders_controller.dart';

/// Port of native `RecommendedItemsScreen`: lists server-recommended items with
/// an editable qty; PROCEED appends the ones with qty ≥ 1 to the order and
/// continues the pipeline (order-minimum check → submit).
class RecommendedItemsScreen extends ConsumerStatefulWidget {
  final int orderId;
  const RecommendedItemsScreen({super.key, this.orderId = -1});

  @override
  ConsumerState<RecommendedItemsScreen> createState() => _State();
}

class _State extends ConsumerState<RecommendedItemsScreen> {
  final Map<String, String> _qty = {};

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(sendOrdersControllerProvider);
    final items = st.recommendedItems;
    final effectiveId =
        st.recommendedOrderId != -1 ? st.recommendedOrderId : widget.orderId;

    return Scaffold(
      appBar: orderAppBar(subtitle: 'RECOMMENDED ITEMS', height: 72),
      bottomNavigationBar: OrderBottomBar(
        onBack: () => context.pop(),
        acceptLabel: 'PROCEED',
        onAccept: () => _proceed(effectiveId, items),
      ),
      body: items.isEmpty
          ? const Center(
              child: Text('No recommended items.', style: TextStyle(color: Colors.grey)))
          : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 0.5, color: Color(0xFFEEEEEE)),
              itemBuilder: (_, i) {
                final it = items[i];
                final qty = _qty[it.itemNumber] ?? it.qty;
                return _Row(
                  itemNumber: it.itemNumber,
                  qty: qty,
                  onChanged: (v) => setState(() => _qty[it.itemNumber] = v),
                );
              },
            ),
    );
  }

  Future<void> _proceed(int orderId, List<RecommendedItemEntry> items) async {
    final lines = <SavedOrderLine>[];
    for (final it in items) {
      final q = int.tryParse(_qty[it.itemNumber] ?? it.qty) ?? 0;
      if (q >= 1) {
        lines.add(SavedOrderLine(itemNumber: it.itemNumber, qty: '$q'));
      }
    }
    final result = await ref
        .read(sendOrdersControllerProvider.notifier)
        .addRecommendedItemsAndContinue(orderId, lines);
    if (!mounted) return;
    switch (result.step) {
      case SendStep.shortfall:
        context.push('${Routes.orderMinimum}?orderId=${result.orderId}');
      case SendStep.proceedSubmit:
      case SendStep.recommended:
        context.push('${Routes.submitOrder}?orderId=${result.orderId}');
    }
  }
}

class _Row extends StatelessWidget {
  final String itemNumber;
  final String qty;
  final ValueChanged<String> onChanged;
  const _Row({required this.itemNumber, required this.qty, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final n = int.tryParse(qty) ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text('# $itemNumber',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          IconButton(
              onPressed: () => onChanged('${n - 1 < 0 ? 0 : n - 1}'),
              icon: Icon(Icons.remove_circle_outline, color: primary)),
          Text('$n', style: const TextStyle(fontWeight: FontWeight.bold)),
          IconButton(
              onPressed: () => onChanged('${n + 1}'),
              icon: Icon(Icons.add_circle_outline, color: primary)),
        ],
      ),
    );
  }
}
