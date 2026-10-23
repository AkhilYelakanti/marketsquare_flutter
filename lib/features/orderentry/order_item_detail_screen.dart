import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/html_text.dart';
import '../../data/db/item_repository.dart';
import 'field_resolver.dart';
import 'order_entry_controller.dart';
import 'order_widgets.dart';
import 'tile_widgets.dart';

/// Port of the native order item-detail view: the configured item tile on top,
/// then the item's detail content (LOV `itemAttributes`, e.g. ITEM_DETAILS_1)
/// rendered below. Qty edits + delete flow through the order controller.
class OrderItemDetailScreen extends ConsumerWidget {
  final Map<String, String>? item;
  const OrderItemDetailScreen({super.key, this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(orderEntryControllerProvider);
    final ctrl = ref.read(orderEntryControllerProvider.notifier);
    final it = item;

    if (it == null) {
      return Scaffold(
        appBar: orderAppBar(subtitle: 'ITEM DETAILS', height: 64),
        bottomNavigationBar: OrderBottomBar(onBack: () => context.pop()),
        body: const Center(
            child: Text('No item selected.', style: TextStyle(color: Colors.grey))),
      );
    }

    final desc = resolveItemField('ITEM_DESCRIPTION', it);
    final number = resolveItemField('ITEM_CODE', it);
    final line = st.lineFor(it);

    // Detail HTML blocks from the LOV itemAttributes fields.
    final details = <String>[];
    for (final attr in st.config.itemAttributes) {
      final raw = resolveItemField(attr, it);
      final text = stripHtml(raw);
      if (text.isNotEmpty) details.add(text);
    }

    return Scaffold(
      appBar: orderAppBar(
        subtitle: st.selectedOrderType ?? 'ITEM DETAILS',
        third: number.isNotEmpty ? '# $number' : null,
        height: 72,
      ),
      bottomNavigationBar: OrderBottomBar(
        onBack: () => context.pop(),
        acceptLabel: 'DONE',
        onAccept: () => context.pop(),
      ),
      body: ListView(
        children: [
          ItemTileCard(
            item: it,
            config: st.config.getOrderTileConfig(st.selectedOrderType),
            qty: line?.qty ?? '0',
            onQty: (v) => ctrl.commitItem(it, v),
            onDelete: () {
              ctrl.removeLine(it);
              context.pop();
            },
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(desc.isEmpty ? (it[ItemRepository.colDesc] ?? '') : desc,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
          if (details.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('No additional item details.',
                  style: TextStyle(color: Colors.black45)),
            )
          else
            for (final d in details)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Text(d, style: const TextStyle(fontSize: 13, height: 1.3)),
              ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
