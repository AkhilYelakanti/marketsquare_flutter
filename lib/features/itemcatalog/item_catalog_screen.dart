import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db/item_repository.dart';
import '../../router/app_routes.dart';
import '../orderentry/order_widgets.dart';

final _catalogMetaProvider = FutureProvider.autoDispose((ref) async {
  return ItemRepository().metadata();
});

class _Opt {
  final String title;
  final IconData icon;
  final String route;
  const _Opt(this.title, this.icon, this.route);
}

/// Port of native `ItemCatalogScreen` landing menu: SEARCH ALL / BY DEPARTMENT /
/// BY C&S CATEGORY / BY NEILSON CATEGORY / SEARCH DEALS / SEARCH IMAGES, as
/// full-width grey cards with centered brand circle icons.
class ItemCatalogScreen extends ConsumerWidget {
  const ItemCatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = Theme.of(context).colorScheme.primary;
    final meta = ref.watch(_catalogMetaProvider);

    const options = [
      _Opt('SEARCH ALL', Icons.search, Routes.itemSearch),
      _Opt('BY DEPARTMENT', Icons.list, Routes.itemDeptList),
      _Opt('BY C&S CATEGORY', Icons.list, Routes.itemCsCatList),
      _Opt('BY NEILSON CATEGORY', Icons.list, Routes.itemNeilsonCatList),
      _Opt('SEARCH DEALS', Icons.attach_money, Routes.searchDeals),
      _Opt('SEARCH IMAGES', Icons.image, Routes.itemImages),
    ];

    return Scaffold(
      appBar: orderAppBar(subtitle: 'ITEM CATALOG', height: 64),
      bottomNavigationBar: OrderBottomBar(onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        children: [
          for (final o in options) ...[
            _OptCard(opt: o, primary: primary),
            const SizedBox(height: 10),
          ],
          meta.maybeWhen(
            data: (m) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                m != null && m.recordCount > 0
                    ? '${m.recordCount} items · updated ${m.lastUpdated}'
                    : 'No catalog loaded — use Refresh Data to sync.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black45, fontSize: 12),
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _OptCard extends StatelessWidget {
  final _Opt opt;
  final Color primary;
  const _OptCard({required this.opt, required this.primary});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFE0E0E0),
      shape: const RoundedRectangleBorder(),
      child: InkWell(
        onTap: () => context.push(opt.route),
        child: SizedBox(
          height: 96,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: primary, width: 3),
                ),
                alignment: Alignment.center,
                child: Icon(opt.icon, color: primary, size: 30),
              ),
              const SizedBox(height: 6),
              Text(opt.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }
}
