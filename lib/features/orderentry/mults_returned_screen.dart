import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'order_entry_controller.dart';
import 'order_widgets.dart';
import 'tile_widgets.dart';

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
              // Render each candidate in the same configured tile format; tapping
              // the tile adds it (qty 1) and returns to Order Filling.
              itemBuilder: (_, i) => ItemTileCard(
                item: candidates[i],
                config: st.config.getOrderTileConfig(st.selectedOrderType),
                onTap: () {
                  ctrl.commitItem(candidates[i], '1');
                  ctrl.clearMults();
                  context.pop();
                },
              ),
            ),
    );
  }
}
