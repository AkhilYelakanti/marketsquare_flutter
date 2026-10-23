import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_routes.dart';
import '../orderentry/order_widgets.dart';
import 'store_orders_controller.dart';

const _valueBlue = Color(0xFF1A49E0);

/// Port of native `StoreOrderDetailScreen` (REVIEW ORDER DETAILS): header fields
/// + dept-grouped line items for a previously sent store order, with a RESPONSE
/// action that fetches the ORDER_RESPONSE receipt.
class StoreOrderDetailScreen extends ConsumerWidget {
  const StoreOrderDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(storeOrdersControllerProvider);
    final detail = st.detail;
    final header = detail?.header;
    final itemCount =
        detail?.deptOrderDetails.fold<int>(0, (a, d) => a + d.orderDetails.length) ?? 0;

    return Scaffold(
      appBar: orderAppBar(
          subtitle: 'REVIEW ORDER DETAILS',
          third: st.customer != null ? 'STORE: ${st.customer!.storeId}' : null,
          height: 72),
      bottomNavigationBar: OrderBottomBar(
        onBack: () => context.pop(),
        acceptLabel: detail != null && !st.loadingDetail ? 'RESPONSE' : null,
        onAccept: detail != null && !st.loadingDetail
            ? () async {
                await ref.read(storeOrdersControllerProvider.notifier).fetchOrderResponse();
                if (context.mounted) context.push(Routes.viewStoreOrdersResponse);
              }
            : null,
      ),
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
                      children: [
                        if (header != null) ...[
                          const SizedBox(height: 8),
                          _kv('STORE ID', header.customerStoreNumber),
                          _kv('BUID', header.buId),
                          _kv('REQUEST TYPE', header.requestType),
                          _kv('ORDER TYPE', header.orderType),
                          _kv('ITEM COUNT', '$itemCount'),
                          const SizedBox(height: 8),
                        ],
                        for (final dept in detail.deptOrderDetails) ...[
                          Container(
                            width: double.infinity,
                            color: const Color(0xFFCFCFCF),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Text(dept.department.isEmpty ? '—' : dept.department,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                          for (final l in dept.orderDetails)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              decoration: const BoxDecoration(
                                border: Border(
                                    bottom: BorderSide(color: Color(0xFFDDDDDD))),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${l.itemDescription.trim()} ${l.itemNumber.trim()}'
                                          .trim(),
                                      style: const TextStyle(
                                          color: _valueBlue,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  RichText(
                                    text: TextSpan(children: [
                                      const TextSpan(
                                          text: 'QTY',
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18)),
                                      TextSpan(
                                          text: l.quantity.trim(),
                                          style: const TextStyle(
                                              color: _valueBlue,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18)),
                                    ]),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ],
                    ),
    );
  }

  /// Right-aligned black label + blue value (native header row).
  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(k,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black)),
            ),
            Expanded(
              child: Text(v.isEmpty ? '—' : v,
                  style: const TextStyle(
                      color: _valueBlue, fontWeight: FontWeight.bold, fontSize: 17)),
            ),
          ],
        ),
      );
}
