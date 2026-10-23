import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../orderentry/order_entry_controller.dart';
import '../orderentry/tile_widgets.dart';

/// Catalog item row rendered with the DEFAULT tile configuration (native
/// parity: every Item Catalog list/search shows items via the default tile).
/// Reuses the order-entry [ItemTileCard] grid renderer; no qty entry in catalog
/// mode. An optional trailing checkbox supports the Manage Saved Items screen.
class CatalogItemTile extends ConsumerWidget {
  final Map<String, String> item;
  final VoidCallback? onTap;
  final bool? checked; // null = no checkbox (plain catalog row)
  final VoidCallback? onToggleChecked;
  const CatalogItemTile({
    super.key,
    required this.item,
    this.onTap,
    this.checked,
    this.onToggleChecked,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(orderEntryControllerProvider).config.defaultTile;
    final tile = ItemTileCard(item: item, config: config, onTap: onTap);
    if (checked == null) return tile;

    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: tile),
        Padding(
          padding: const EdgeInsets.only(right: 10, left: 4),
          child: InkWell(
            onTap: onToggleChecked,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: primary,
                border: Border.all(color: Colors.black38, width: 2),
              ),
              child: checked!
                  ? const Icon(Icons.check, color: Colors.white, size: 30)
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
