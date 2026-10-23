import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../orderentry/order_widgets.dart';
import 'store_orders_controller.dart';

const _valueBlue = Color(0xFF1A49E0);

/// Port of native `StoreOrderResponseScreen` (REVIEW ORDER RECEIPT): the
/// ORDER_RESPONSE acknowledgement for a previously sent order.
class StoreOrderResponseScreen extends ConsumerWidget {
  const StoreOrderResponseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(storeOrdersControllerProvider);
    final r = st.response;

    final fields = r == null
        ? <MapEntry<String, String>>[]
        : [
            MapEntry('acknowledgementId', r.acknowledgementId),
            MapEntry('confirmationId', r.confirmationId),
            MapEntry('orderDate', r.orderDate),
            MapEntry('status', r.status),
            MapEntry('storeId', r.storeId),
            MapEntry('requestType', r.requestType),
            MapEntry('billingDate', r.billingDate),
            MapEntry('estimatedShipDate', r.estimatedShipDate),
            MapEntry('estimatedDeliveryDate', r.estimatedDeliveryDate),
          ];

    return Scaffold(
      appBar: orderAppBar(
          subtitle: 'REVIEW ORDER RECEIPT',
          third: st.customer != null ? 'STORE: ${st.customer!.storeId}' : null,
          height: 72),
      bottomNavigationBar: OrderBottomBar(onBack: () => context.pop()),
      body: st.loadingResponse
          ? const Center(child: CircularProgressIndicator())
          : st.responseError.isNotEmpty
              ? Center(
                  child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(st.responseError,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey))))
              : r == null
                  ? const Center(
                      child: Text('No response data available.',
                          style: TextStyle(color: Colors.grey)))
                  : ListView(
                      children: [
                        for (final f in fields) _field(f.key, f.value),
                      ],
                    ),
    );
  }

  Widget _field(String label, String value) => Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFF999999))),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(value.isEmpty ? '—' : value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      color: _valueBlue, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      );
}
