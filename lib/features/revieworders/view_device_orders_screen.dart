import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db/pending_order.dart';
import '../../data/db/pending_order_dao.dart';
import '../../data/models/order_models.dart';
import '../orderentry/order_widgets.dart';

final _deviceOrdersProvider = FutureProvider.autoDispose(
    (ref) async => PendingOrderDao().listAll());

/// Port of native `ViewDeviceOrdersScreen`: all orders stored on the device
/// (UNSENT + SENT), from the local DB. Tap an order to view its lines.
class ViewDeviceOrdersScreen extends ConsumerWidget {
  const ViewDeviceOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(_deviceOrdersProvider);
    return Scaffold(
      appBar: orderAppBar(subtitle: 'DEVICE ORDERS', height: 60),
      bottomNavigationBar: OrderBottomBar(onBack: () => context.pop()),
      body: orders.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Could not load orders.')),
        data: (list) => list.isEmpty
            ? const Center(
                child: Text('No orders on this device.',
                    style: TextStyle(color: Colors.grey)))
            : ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: Color(0xFFDDDDDD)),
                itemBuilder: (_, i) => _Row(order: list[i], onTap: () => _show(context, list[i])),
              ),
      ),
    );
  }

  void _show(BuildContext context, PendingOrder o) {
    final lines = _decode(o.linesJson);
    showDialog<void>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text('${o.orderType} · ${o.status}'),
        content: SizedBox(
          width: double.maxFinite,
          child: lines.isEmpty
              ? const Text('No lines.')
              : ListView(
                  shrinkWrap: true,
                  children: [
                    Text('PO: ${o.poNumber}'),
                    if (o.confirmationNumber.isNotEmpty)
                      Text('Confirmation #: ${o.confirmationNumber}'),
                    const Divider(),
                    for (final l in lines)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                            '${l.qty} × ${l.itemDescription.isEmpty ? l.itemNumber : l.itemDescription}'),
                      ),
                  ],
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dctx), child: const Text('CLOSE')),
        ],
      ),
    );
  }

  List<SavedOrderLine> _decode(String json) {
    try {
      return (jsonDecode(json) as List)
          .map((e) => SavedOrderLine.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}

class _Row extends StatelessWidget {
  final PendingOrder order;
  final VoidCallback onTap;
  const _Row({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final sent = order.status == 'SENT';
    return ListTile(
      onTap: onTap,
      title: Text('${order.orderType}  •  ${order.partition}',
          style: TextStyle(fontWeight: FontWeight.bold, color: primary)),
      subtitle: Text(
          'Items ${order.itemCount} · Qty ${order.totalQty} · \$${order.totalValue}'
          '${order.poNumber.isNotEmpty ? '\nPO: ${order.poNumber}' : ''}'),
      isThreeLine: order.poNumber.isNotEmpty,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: sent ? const Color(0xFF2E7D32) : const Color(0xFFFFA000),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(order.status,
            style: const TextStyle(
                color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
