import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db/pending_order.dart';
import '../../router/app_routes.dart';
import '../orderentry/order_widgets.dart';
import 'send_orders_controller.dart';

/// Port of native `SendOrdersScreen`: list of UNSENT orders, select one, SEND
/// SELECTED runs the pre-submit pipeline then routes to the right screen.
class SendOrdersScreen extends ConsumerStatefulWidget {
  final int currentOrderId;
  const SendOrdersScreen({super.key, this.currentOrderId = -1});

  @override
  ConsumerState<SendOrdersScreen> createState() => _State();
}

class _State extends ConsumerState<SendOrdersScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.currentOrderId != -1) {
      WidgetsBinding.instance.addPostFrameCallback((_) => ref
          .read(sendOrdersControllerProvider.notifier)
          .initCurrentOrder(widget.currentOrderId));
    }
  }

  Future<void> _send() async {
    final ctrl = ref.read(sendOrdersControllerProvider.notifier);
    final id = ref.read(sendOrdersControllerProvider).firstSelectedId;
    if (id == -1) return;
    final result = await ctrl.beginSend(id);
    if (!mounted) return;
    switch (result.step) {
      case SendStep.proceedSubmit:
        context.push('${Routes.submitOrder}?orderId=${result.orderId}');
      case SendStep.recommended:
        context.push('${Routes.recommendedItems}?orderId=${result.orderId}');
      case SendStep.shortfall:
        context.push('${Routes.orderMinimum}?orderId=${result.orderId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final st = ref.watch(sendOrdersControllerProvider);
    final ctrl = ref.read(sendOrdersControllerProvider.notifier);

    return Scaffold(
      appBar: orderAppBar(subtitle: 'SELECT ORDER TO SEND', height: 60),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: st.orders.isEmpty
                    ? const Center(
                        child: Text('No unsent orders.',
                            style: TextStyle(color: Colors.grey, fontSize: 15)))
                    : ListView.separated(
                        itemCount: st.orders.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1, color: Color(0xFFDDDDDD)),
                        itemBuilder: (_, i) {
                          final o = st.orders[i];
                          return _OrderCard(
                            order: o,
                            selected: st.selectedIds.contains(o.id),
                            onToggle: () => ctrl.toggleSelection(o.id),
                            onDelete: () => _confirmDelete(o.id),
                          );
                        },
                      ),
              ),
              _BottomBar(
                enabled: st.hasSelectedUnsent && st.inflight == SendInflight.idle,
                label: st.inflight == SendInflight.idle ? 'SEND SELECTED' : 'CHECKING…',
                onBack: () => context.pop(),
                onSend: _send,
              ),
            ],
          ),
          if (st.inflight != SendInflight.idle)
            _Overlay(
              primary: primary,
              label: st.inflight == SendInflight.checkingRecommended
                  ? 'Checking for recommended items…'
                  : 'Loading Order Minimum Requirements…',
            ),
        ],
      ),
    );
  }

  void _confirmDelete(int id) {
    showDialog<void>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('Delete Order'),
        content: const Text('Remove this pending order? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(dctx);
              ref.read(sendOrdersControllerProvider.notifier).deleteOrder(id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final PendingOrder order;
  final bool selected;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  const _OrderCard(
      {required this.order,
      required this.selected,
      required this.onToggle,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onToggle,
      child: Container(
        color: selected ? const Color(0xFFE8F5E9) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(order.orderType,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13, color: primary)),
                      if (order.partition.isNotEmpty)
                        Text('  •  ${order.partition}',
                            style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFA000),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('UNSENT',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(spacing: 8, children: [
                    _chip(primary, 'Items', '${order.itemCount}'),
                    _chip(primary, 'Qty', '${order.totalQty}'),
                    _chip(primary, 'Value', '\$${order.totalValue}'),
                  ]),
                  if (order.poNumber.isNotEmpty)
                    Text('PO: ${order.poNumber}',
                        style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),
            IconButton(
                onPressed: onDelete, icon: const Icon(Icons.delete_outline, color: Colors.black38)),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? primary : Colors.transparent,
                border: Border.all(color: primary, width: 2),
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(Color primary, String label, String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(4)),
        child: Text('$label: $value',
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: primary)),
      );
}

class _BottomBar extends StatelessWidget {
  final bool enabled;
  final String label;
  final VoidCallback onBack;
  final VoidCallback onSend;
  const _BottomBar(
      {required this.enabled,
      required this.label,
      required this.onBack,
      required this.onSend});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      color: primary,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: onBack,
            child: Row(children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2)),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              const Text('BACK',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ]),
          ),
          InkWell(
            onTap: enabled ? onSend : null,
            child: Row(children: [
              Text(label,
                  style: TextStyle(
                      color: enabled ? Colors.white : Colors.white.withValues(alpha: 0.4),
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              const SizedBox(width: 6),
              Icon(Icons.send,
                  color: enabled ? Colors.white : Colors.white.withValues(alpha: 0.4),
                  size: 20),
            ]),
          ),
        ],
      ),
    );
  }
}

class _Overlay extends StatelessWidget {
  final Color primary;
  final String label;
  const _Overlay({required this.primary, required this.label});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black38,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: primary),
                const SizedBox(height: 16),
                Text(label, style: const TextStyle(color: Colors.black87)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
