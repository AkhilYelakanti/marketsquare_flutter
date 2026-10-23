import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db/item_repository.dart';
import '../../data/session/session_providers.dart';
import '../../router/app_routes.dart';
import '../orderentry/order_widgets.dart';

/// Port of native `ManageSavedItemsScreen`: the user's saved item codes,
/// resolved against the catalog, with remove.
class SavedItemsScreen extends ConsumerStatefulWidget {
  const SavedItemsScreen({super.key});

  @override
  ConsumerState<SavedItemsScreen> createState() => _State();
}

class _State extends ConsumerState<SavedItemsScreen> {
  final _repo = ItemRepository();
  bool _loading = true;
  List<Map<String, String>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final codes = ref.read(sessionManagerProvider).getSavedItemCodes();
    final items = <Map<String, String>>[];
    for (final code in codes) {
      final m = await _repo.queryByExactCode(code);
      items.add(m.isNotEmpty
          ? m.first
          : {ItemRepository.colItem: code, ItemRepository.colDesc: 'Item $code'});
    }
    if (mounted) {
      setState(() {
        _items = items;
        _loading = false;
      });
    }
  }

  Future<void> _remove(String code) async {
    final sm = ref.read(sessionManagerProvider);
    final codes = {...sm.getSavedItemCodes()}..remove(code);
    await sm.saveSavedItemCodes(codes);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: orderAppBar(subtitle: 'SAVED ITEMS', height: 60),
      bottomNavigationBar: OrderBottomBar(onBack: () => context.pop()),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(
                  child: Text('No saved items.', style: TextStyle(color: Colors.grey)))
              : ListView.separated(
                  itemCount: _items.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 0.5, color: Color(0xFFEEEEEE)),
                  itemBuilder: (_, i) {
                    final it = _items[i];
                    final number = it[ItemRepository.colItem] ?? '';
                    final desc = it[ItemRepository.colDesc] ?? '';
                    return ListTile(
                      title: Text(desc.isEmpty ? number : desc,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('# $number'),
                      onTap: () => context.push(Routes.itemDetail, extra: it),
                      trailing: IconButton(
                        icon: Icon(Icons.bookmark_remove, color: primary),
                        onPressed: () => _remove(number),
                      ),
                    );
                  },
                ),
    );
  }
}
