import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db/item_repository.dart';
import 'order_entry_controller.dart';
import 'order_widgets.dart';

/// Port of native `MultsReturnedScreen` ("MULTIPLE ITEMS RETURNED"): shown when
/// one scanned/keyed code resolves to several catalog rows. Tapping a row adds
/// it (qty 1) and returns to Order Filling.
class MultsReturnedScreen extends ConsumerWidget {
  const MultsReturnedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(orderEntryControllerProvider);
    final ctrl = ref.read(orderEntryControllerProvider.notifier);
    final candidates = st.multsCandidates;

    void goBack() {
      ctrl.clearMults();
      context.pop();
    }

    return Scaffold(
      appBar: orderAppBar(
        subtitle: 'MULTIPLE ITEMS RETURNED',
        third: 'VIEWING ${candidates.length} ITEMS',
        height: 84,
      ),
      bottomNavigationBar: OrderBottomBar(onBack: goBack),
      body: candidates.isEmpty
          ? const Center(child: Text('No matching items.', style: TextStyle(color: Colors.grey)))
          : ListView.separated(
              itemCount: candidates.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 0.5, color: Color(0xFFEEEEEE)),
              itemBuilder: (_, i) {
                final item = candidates[i];
                final number = item[ItemRepository.colItem] ?? '';
                final desc = item[ItemRepository.colDesc] ?? '';
                return ListTile(
                  title: Text(desc.isEmpty ? number : desc,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('# $number'),
                  trailing: const Icon(Icons.add_circle_outline),
                  onTap: () {
                    ctrl.commitItem(item, '1');
                    ctrl.clearMults();
                    context.pop();
                  },
                );
              },
            ),
    );
  }
}
