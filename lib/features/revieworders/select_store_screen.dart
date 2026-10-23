import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_routes.dart';
import '../orderentry/order_widgets.dart';
import 'store_orders_controller.dart';

/// Port of native `SelectStoreScreen`: pick a store to view its previous orders.
class SelectStoreScreen extends ConsumerStatefulWidget {
  const SelectStoreScreen({super.key});

  @override
  ConsumerState<SelectStoreScreen> createState() => _State();
}

class _State extends ConsumerState<SelectStoreScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final ctrl = ref.read(storeOrdersControllerProvider.notifier);
    final q = _search.trim().toLowerCase();
    final customers = ctrl.customers
        .where((c) =>
            q.isEmpty ||
            c.storeId.toLowerCase().contains(q) ||
            c.storeName.toLowerCase().contains(q))
        .toList();

    return Scaffold(
      appBar: orderAppBar(subtitle: 'SELECT STORE', height: 60),
      bottomNavigationBar: OrderBottomBar(onBack: () => context.pop()),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search store',
                prefixIcon: Icon(Icons.search, color: primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: customers.isEmpty
                ? const Center(
                    child: Text('No stores configured.', style: TextStyle(color: Colors.grey)))
                : ListView.separated(
                    itemCount: customers.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 0.5, color: Color(0xFFEEEEEE)),
                    itemBuilder: (_, i) {
                      final c = customers[i];
                      return ListTile(
                        leading: Icon(Icons.store, color: primary),
                        title: Text(c.storeId,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: c.storeName.isEmpty ? null : Text(c.storeName),
                        onTap: () async {
                          await ctrl.selectCustomer(c);
                          if (context.mounted) context.push(Routes.viewStoreOrdersList);
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
