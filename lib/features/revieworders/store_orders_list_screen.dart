import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/order_models.dart';
import '../../router/app_routes.dart';
import '../orderentry/order_widgets.dart';
import 'store_orders_controller.dart';

const _valueBlue = Color(0xFF1A49E0);

/// Port of native `StoreOrdersListScreen`: FROM/TO/CONFIRM filter bar + search,
/// then recent orders (RECENT_ORDERS-RESPONSE3) as CONFIRM #/PARTITION/STATUS
/// rows for the selected store.
class StoreOrdersListScreen extends ConsumerStatefulWidget {
  const StoreOrdersListScreen({super.key});

  @override
  ConsumerState<StoreOrdersListScreen> createState() => _State();
}

class _State extends ConsumerState<StoreOrdersListScreen> {
  final _from = TextEditingController();
  final _to = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _search() {
    ref.read(storeOrdersControllerProvider.notifier).fetchOrders(
          fromDate: _from.text.trim(),
          toDate: _to.text.trim(),
          confirmationId: _confirm.text.trim(),
        );
  }

  void _clear() {
    _from.clear();
    _to.clear();
    _confirm.clear();
    ref.read(storeOrdersControllerProvider.notifier).fetchOrders();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final st = ref.watch(storeOrdersControllerProvider);
    final ctrl = ref.read(storeOrdersControllerProvider.notifier);

    return Scaffold(
      appBar: orderAppBar(
          subtitle: 'REVIEW ORDERS',
          third: st.customer != null ? 'STORE: ${st.customer!.storeId}' : null,
          height: 72),
      bottomNavigationBar: OrderBottomBar(onBack: () => context.pop()),
      body: Column(
        children: [
          _filterBar(primary),
          const Divider(height: 1),
          Expanded(
            child: st.loadingOrders
                ? const Center(child: CircularProgressIndicator())
                : st.ordersError.isNotEmpty
                    ? Center(
                        child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(st.ordersError,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.grey))))
                    : ListView.builder(
                        itemCount: st.orders.length,
                        itemBuilder: (_, i) => _OrderRow(
                          order: st.orders[i],
                          onTap: () async {
                            await ctrl.selectOrderAndFetch(st.orders[i]);
                            if (context.mounted) {
                              context.push(Routes.viewStoreOrdersDetail);
                            }
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filterBar(Color primary) {
    Widget field(String label, TextEditingController c) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                  width: 110,
                  child: Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14))),
              Expanded(
                child: TextField(
                  controller: c,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        );

    Widget circleBtn(IconData icon, VoidCallback onTap) => InkWell(
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              children: [
                field('FROM DATE', _from),
                field('TO DATE', _to),
                field('CONFIRM #', _confirm),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              circleBtn(Icons.close, _clear),
              const SizedBox(height: 12),
              circleBtn(Icons.search, _search),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  final OrderSummary order;
  final VoidCallback onTap;
  const _OrderRow({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Widget kv(String k, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Row(
            children: [
              Text(k,
                  style:
                      const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text(v,
                  style: const TextStyle(
                      color: _valueBlue, fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
        );

    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      kv('CONFIRM #', order.confirmationId),
                      kv('PARTITION', order.storePartition),
                      kv('STATUS', order.status),
                    ],
                  ),
                ),
                Text(order.orderDate,
                    style: const TextStyle(
                        color: _valueBlue, fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
          ),
          // Grey divider band (native row separator).
          Container(height: 26, color: const Color(0xFFCFCFCF)),
        ],
      ),
    );
  }
}
