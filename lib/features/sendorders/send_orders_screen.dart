import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db/pending_order.dart';
import '../../data/session/session_providers.dart';
import '../../router/app_routes.dart';
import '../orderentry/order_widgets.dart';
import 'send_orders_controller.dart';

const _selectedGreen = Color(0xFFBCE3B7);
const _labelGrey = Color(0xFF808080);

/// Port of native `SendOrdersScreen` (SELECT ORDER TO SEND): every pending order
/// shown with ITEMS/QTY/VALUE + PO/Comments/Delivery/Cube and a per-row send
/// circle. One order selected at a time; submit via SEND SELECTED or delete it.
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

  /// True when the selected order originated from an approval (has a
  /// confirmation number) — shows APPROVED SEND SELECTED like native.
  bool _selectedIsApproval(SendOrdersState st) {
    if (st.selectedIds.isEmpty) return false;
    final id = st.firstSelectedId;
    final o = st.orders.where((e) => e.id == id);
    return o.isNotEmpty && o.first.confirmationNumber.trim().isNotEmpty;
  }

  Future<void> _send(int id) async {
    final ctrl = ref.read(sendOrdersControllerProvider.notifier);
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
    final store = st.orders.isNotEmpty
        ? st.orders.first.storeId
        : ref.watch(sessionManagerProvider).getActiveStoreId();

    return Scaffold(
      appBar: orderAppBar(
          subtitle: 'SELECT ORDER TO SEND',
          third: store.isEmpty ? null : 'STORE: $store',
          height: 72),
      body: Stack(
        children: [
          Column(
            children: [
              // STORE # band
              Container(
                width: double.infinity,
                color: const Color(0xFFCFCFCF),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    const Text('STORE #',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(width: 20),
                    Text(store,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
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
                          final sel = st.selectedIds.contains(o.id);
                          return _OrderCard(
                            order: o,
                            selected: sel,
                            onToggle: () => ctrl.toggleSelection(o.id),
                            onDelete: () => _confirmDelete(o.id),
                            onSend: sel ? () => _send(o.id) : null,
                          );
                        },
                      ),
              ),
              _BottomBar(
                enabled: st.hasSelectedUnsent && st.inflight == SendInflight.idle,
                approved: _selectedIsApproval(st),
                onBack: () => context.pop(),
                onSend: () => _send(st.firstSelectedId),
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
  final VoidCallback? onSend;
  const _OrderCard(
      {required this.order,
      required this.selected,
      required this.onToggle,
      required this.onDelete,
      this.onSend});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onToggle,
      onLongPress: onDelete,
      child: Container(
        color: selected ? _selectedGreen : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Request type + partition
                  Row(
                    children: [
                      Expanded(
                        child: Text('${order.orderType} ,',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 17)),
                      ),
                      Text(order.partition,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 17)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Two-column detail grid
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _kv('ITEMS', '${order.itemCount}'),
                            _kv('QTY', '${order.totalQty}'),
                            _kv('VALUE', '\$${order.totalValue}'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _kv('PO', order.poNumber),
                            _kv('Comments', order.comments),
                            _kv('Delivery Date', order.deliveryDate),
                            _kv('Cube', order.totalCube),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Per-row send circle: filled blue when idle, white w/ envelope-up
            // (send) when this row is selected.
            InkWell(
              onTap: selected ? onSend : onToggle,
              customBorder: const CircleBorder(),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? Colors.white : primary,
                  border: Border.all(color: primary, width: 2),
                ),
                child: selected
                    ? Icon(Icons.outgoing_mail, color: primary, size: 30)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: RichText(
          text: TextSpan(children: [
            TextSpan(
                text: '$label: ',
                style: const TextStyle(
                    color: _labelGrey, fontSize: 13, fontWeight: FontWeight.w500)),
            TextSpan(
                text: value,
                style: const TextStyle(
                    color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold)),
          ]),
        ),
      );
}

class _BottomBar extends StatelessWidget {
  final bool enabled;
  final bool approved;
  final VoidCallback onBack;
  final VoidCallback onSend;
  const _BottomBar(
      {required this.enabled,
      this.approved = false,
      required this.onBack,
      required this.onSend});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final fade = enabled ? Colors.white : Colors.white.withValues(alpha: 0.4);
    return Container(
      color: primary,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: onBack,
            child: Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2)),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              const Text('BACK',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
          ),
          InkWell(
            onTap: enabled ? onSend : null,
            child: Row(children: [
              Text(approved ? 'APPROVED\nSEND SELECTED' : 'SEND SELECTED',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: fade, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(width: 10),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    shape: BoxShape.circle, border: Border.all(color: fade, width: 2)),
                child: Icon(Icons.outgoing_mail, color: fade, size: 22),
              ),
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
