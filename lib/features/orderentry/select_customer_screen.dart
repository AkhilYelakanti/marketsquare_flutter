import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/order_models.dart';
import '../../router/app_routes.dart';
import '../datasync/item_refresh_service.dart';
import 'order_entry_controller.dart';
import 'order_widgets.dart';

/// Port of native `SelectCustomerScreen`: searchable store list → select → order
/// type. (Native also re-fetches per-store LOV1 config + offers image download;
/// that refresh is a follow-up tied to the Data Sync module.)
class SelectCustomerScreen extends ConsumerStatefulWidget {
  const SelectCustomerScreen({super.key});

  @override
  ConsumerState<SelectCustomerScreen> createState() =>
      _SelectCustomerScreenState();
}

class _SelectCustomerScreenState extends ConsumerState<SelectCustomerScreen> {
  String _search = '';

  @override
  void initState() {
    super.initState();
    // Delta inventory refresh on order-entry enter (native parity; non-blocking,
    // quietly updates stock/cost against the current item table).
    Future.microtask(() =>
        ref.read(itemRefreshServiceProvider).runDeltaInventoryRefresh((_) {}));
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final st = ref.watch(orderEntryControllerProvider);
    final ctrl = ref.read(orderEntryControllerProvider.notifier);

    final q = _search.trim().toLowerCase();
    final filtered = q.isEmpty
        ? st.config.customers
        : st.config.customers.where((c) {
            return c.storeId.toLowerCase().contains(q) ||
                c.storeName.toLowerCase().contains(q);
          }).toList();

    return Scaffold(
      appBar: orderAppBar(subtitle: 'SELECT CUSTOMER'),
      bottomNavigationBar: OrderBottomBar(onBack: () => context.go(Routes.dashboard)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search store ID or name',
                prefixIcon: Icon(Icons.search, color: primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No customers found.\nCheck LOV1 customer config.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 0.5, color: Color(0xFFEEEEEE)),
                    itemBuilder: (_, i) {
                      final c = filtered[i];
                      return _CustomerRow(
                        customer: c,
                        onTap: () {
                          ctrl.selectCustomer(c);
                          context.push(Routes.selectOrderType);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _CustomerRow extends StatelessWidget {
  final CustomerEntry customer;
  final VoidCallback onTap;
  const _CustomerRow({required this.customer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primary.withValues(alpha: 0.12),
              ),
              child: Icon(Icons.store, color: primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(customer.storeId,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black)),
                  if (customer.storeName.isNotEmpty)
                    Text(customer.storeName,
                        style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
