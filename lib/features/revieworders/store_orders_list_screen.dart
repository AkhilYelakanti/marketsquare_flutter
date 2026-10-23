import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_routes.dart';
import '../orderentry/order_widgets.dart';
import 'store_orders_controller.dart';

/// Port of native `StoreOrdersListScreen`: recent orders for the selected store.
class StoreOrdersListScreen extends ConsumerWidget {
  const StoreOrdersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = Theme.of(context).colorScheme.primary;
    final st = ref.watch(storeOrdersControllerProvider);
    final ctrl = ref.read(storeOrdersControllerProvider.notifier);

    return Scaffold(
      appBar: orderAppBar(
          subtitle: 'STORE ORDERS',
          third: st.customer != null ? 'Store: ${st.customer!.storeId}' : null,
          height: 72),
      bottomNavigationBar: OrderBottomBar(onBack: () => context.pop()),
      body: st.loadingOrders
          ? const Center(child: CircularProgressIndicator())
          : st.ordersError.isNotEmpty
              ? Center(
                  child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(st.ordersError,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey))))
              : ListView.separated(
                  itemCount: st.orders.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  itemBuilder: (_, i) {
                    final o = st.orders[i];
                    return ListTile(
                      title: Text('Conf #${o.confirmationId}',
                          style: TextStyle(fontWeight: FontWeight.bold, color: primary)),
                      subtitle: Text(
                          '${o.orderDate}${o.storePartition.isNotEmpty ? '  •  ${o.storePartition}' : ''}'
                          '${o.status.isNotEmpty ? '  •  ${o.status}' : ''}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        await ctrl.selectOrderAndFetch(o);
                        if (context.mounted) context.push(Routes.viewStoreOrdersDetail);
                      },
                    );
                  },
                ),
    );
  }
}
