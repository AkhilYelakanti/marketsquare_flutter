import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db/item_repository.dart';
import '../../router/app_routes.dart';

final _catalogMetaProvider = FutureProvider.autoDispose((ref) async {
  return ItemRepository().metadata();
});

/// Port of native `ItemCatalogScreen` landing: search entry + record count.
/// (Department/category/deals/images/saved sub-screens remain placeholders.)
class ItemCatalogScreen extends ConsumerWidget {
  const ItemCatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = Theme.of(context).colorScheme.primary;
    final meta = ref.watch(_catalogMetaProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('ITEM CATALOG')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            meta.when(
              data: (m) => Text(
                m != null && m.recordCount > 0
                    ? '${m.recordCount} items · last updated ${m.lastUpdated}'
                    : 'No catalog loaded. Use Refresh Data to sync (or load the sample catalog).',
                style: const TextStyle(color: Colors.black54),
              ),
              loading: () => const Text('…'),
              error: (_, _) => const Text('No catalog loaded.'),
            ),
            const SizedBox(height: 16),
            _CatalogTile(
              icon: Icons.search,
              label: 'SEARCH ALL ITEMS',
              primary: primary,
              onTap: () => context.push(Routes.itemSearch),
            ),
            const SizedBox(height: 10),
            _CatalogTile(
              icon: Icons.category,
              label: 'DEPARTMENTS',
              primary: primary,
              onTap: () => context.push(Routes.itemDeptList),
            ),
            const SizedBox(height: 10),
            _CatalogTile(
              icon: Icons.category_outlined,
              label: 'CS CATEGORIES',
              primary: primary,
              onTap: () => context.push(Routes.itemCsCatList),
            ),
            const SizedBox(height: 10),
            _CatalogTile(
              icon: Icons.category_outlined,
              label: 'NEILSON CATEGORIES',
              primary: primary,
              onTap: () => context.push(Routes.itemNeilsonCatList),
            ),
            const SizedBox(height: 10),
            _CatalogTile(
              icon: Icons.local_offer,
              label: 'SEARCH DEALS',
              primary: primary,
              onTap: () => context.push(Routes.searchDeals),
            ),
            const SizedBox(height: 10),
            _CatalogTile(
              icon: Icons.bookmark,
              label: 'SAVED ITEMS',
              primary: primary,
              onTap: () => context.push(Routes.manageSavedItems),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color primary;
  final VoidCallback onTap;
  const _CatalogTile(
      {required this.icon,
      required this.label,
      required this.primary,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFE0E0E0),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Row(
            children: [
              Icon(icon, color: primary, size: 32),
              const SizedBox(width: 16),
              Text(label,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
