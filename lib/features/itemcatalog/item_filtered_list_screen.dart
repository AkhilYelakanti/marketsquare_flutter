import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db/item_repository.dart';
import '../../router/app_routes.dart';
import '../orderentry/order_widgets.dart';

/// Filtered item list — department, category, or deals. Reads the filter from
/// query params. Port of native `ItemFilteredListScreen` / `SearchDealsScreen`.
class ItemFilteredListScreen extends ConsumerStatefulWidget {
  final String? dept;
  final String? categoryKind;
  final String? category;
  final bool dealsOnly;
  const ItemFilteredListScreen({
    super.key,
    this.dept,
    this.categoryKind,
    this.category,
    this.dealsOnly = false,
  });

  @override
  ConsumerState<ItemFilteredListScreen> createState() => _State();
}

class _State extends ConsumerState<ItemFilteredListScreen> {
  final _repo = ItemRepository();
  bool _loading = true;
  List<Map<String, String>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _repo.queryItems(
      dept: widget.dept,
      categoryKind: widget.categoryKind,
      category: widget.category,
      dealsOnly: widget.dealsOnly,
    );
    if (mounted) {
      setState(() {
        _items = items;
        _loading = false;
      });
    }
  }

  String get _title {
    if (widget.dealsOnly) return 'DEALS';
    if (widget.category != null) return widget.category!;
    if (widget.dept != null) return widget.dept!;
    return 'ITEMS';
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: orderAppBar(subtitle: _title, third: '${_items.length} item(s)', height: 72),
      bottomNavigationBar: OrderBottomBar(onBack: () => context.pop()),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(
                  child: Text('No items.', style: TextStyle(color: Colors.grey)))
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
                      trailing: Icon(Icons.chevron_right, color: primary),
                      onTap: () => context.push(Routes.itemDetail, extra: it),
                    );
                  },
                ),
    );
  }
}
