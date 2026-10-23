import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../orderentry/order_widgets.dart';
import 'store_orders_controller.dart';

/// Port of native `StoreOrderDetailScreen`: header + dept-grouped line items for
/// a previously sent store order.
class StoreOrderDetailScreen extends ConsumerWidget {
  const StoreOrderDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = Theme.of(context).colorScheme.primary;
    final st = ref.watch(storeOrdersControllerProvider);
    final detail = st.detail;
    final header = detail?.header;

    return Scaffold(
      appBar: orderAppBar(subtitle: 'ORDER DETAIL', height: 60),
      bottomNavigationBar: OrderBottomBar(onBack: () => context.pop()),
      body: st.loadingDetail
          ? const Center(child: CircularProgressIndicator())
          : st.detailError.isNotEmpty
              ? Center(
                  child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(st.detailError,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey))))
              : detail == null
                  ? const SizedBox.shrink()
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (header != null)
                          Container(
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
                                Text(
                                    header.requestType.isEmpty
                                        ? 'ORDER'
                                        : header.requestType,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: primary,
                                        fontSize: 15)),
                                if (header.confirmationId.isNotEmpty)
                                  Text('Confirmation #: ${header.confirmationId}'),
                                if (header.orderCreationDate.isNotEmpty)
                                  Text('Created: ${header.orderCreationDate}'),
                                if (header.requestedDeliveryDate.isNotEmpty)
                                  Text('Delivery: ${header.requestedDeliveryDate}'),
                                if (header.currentStatus.isNotEmpty)
                                  Text('Status: ${header.currentStatus}'),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),
                        for (final dept in detail.deptOrderDetails) ...[
                          Container(
                            width: double.infinity,
                            color: const Color(0xFFEFEFEF),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            child: Text(dept.department.isEmpty ? '—' : dept.department,
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          for (final l in dept.orderDetails)
                            ListTile(
                              dense: true,
                              title: Text(l.itemDescription.isEmpty
                                  ? l.itemNumber
                                  : l.itemDescription),
                              subtitle: Text('# ${l.itemNumber}'),
                              trailing: Text('Qty ${l.quantity}',
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ],
                    ),
    );
  }
}
