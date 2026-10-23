import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/db/item_repository.dart';
import '../../router/app_routes.dart';

/// Port of native `ItemDetailScreen`: shows the selected item's key fields plus
/// its full column set. The item map is passed via go_router `extra`.
class ItemDetailScreen extends StatelessWidget {
  final Map<String, String>? item;
  const ItemDetailScreen({super.key, this.item});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final it = item ?? const {};
    final desc = it[ItemRepository.colDesc] ?? '';
    final number = it[ItemRepository.colItem] ?? '';

    // Hide the canonical alias keys from the raw dump (they duplicate columns).
    const aliases = {
      ItemRepository.colItem,
      ItemRepository.colDesc,
      ItemRepository.colPack,
      ItemRepository.colUpc,
      ItemRepository.colDept,
      ItemRepository.colAdEffective,
      ItemRepository.colAllowance,
      ItemRepository.colCube,
      ItemRepository.colMults,
    };
    final raw = it.entries.where((e) => !aliases.contains(e.key)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ITEM DETAIL'),
        actions: [
          if (number.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.image),
              tooltip: 'Images',
              onPressed: () => context.push('${Routes.itemImages}?code=$number'),
            ),
        ],
      ),
      body: it.isEmpty
          ? const Center(child: Text('No item selected.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(desc, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('# $number', style: TextStyle(color: primary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                _kv('Pack', it[ItemRepository.colPack]),
                _kv('UPC', it[ItemRepository.colUpc]),
                _kv('Department', it[ItemRepository.colDept]),
                _kv('Ad Effective', it[ItemRepository.colAdEffective]),
                _kv('Allowance', it[ItemRepository.colAllowance]),
                _kv('Cube', it[ItemRepository.colCube]),
                const Divider(height: 32),
                const Text('All columns',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                for (final e in raw) _kv(e.key, e.value),
              ],
            ),
    );
  }

  Widget _kv(String k, String? v) {
    if (v == null || v.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(k, style: const TextStyle(color: Colors.black54, fontSize: 13)),
          ),
          Expanded(child: Text(v, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
