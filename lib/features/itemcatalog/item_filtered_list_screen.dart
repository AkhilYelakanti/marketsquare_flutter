import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db/item_repository.dart';
import '../../data/session/session_providers.dart';
import '../../router/app_routes.dart';
import '../orderentry/order_widgets.dart';
import 'catalog_tile.dart';

/// Filtered item list — department, category, or deals. Renders rows with the
/// default tile config, an inline filter field, a VIEWING count, and (on a
/// department list, when savedItems is enabled) a MANAGE SAVED ITEMS action.
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
  String _filter = '';
  Timer? _debounce;
  List<Map<String, String>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await _repo.queryItems(
      dept: widget.dept,
      categoryKind: widget.categoryKind,
      category: widget.category,
      dealsOnly: widget.dealsOnly,
      search: _filter.trim().isEmpty ? null : _filter.trim(),
    );
    if (mounted) {
      setState(() {
        _items = items;
        _loading = false;
      });
    }
  }

  void _onFilter(String v) {
    setState(() => _filter = v);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _load);
  }

  String get _title {
    if (widget.dealsOnly) return 'SEARCH DEALS';
    if (widget.category != null) {
      return 'BY ${widget.categoryKind == 'NEILSON' ? 'NEILSON' : 'C&S'} CATEGORY - ${widget.category}';
    }
    if (widget.dept != null) return 'BY DEPARTMENT - ${widget.dept}';
    return 'ITEMS';
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final parts = _title.split(' - ');
    final sm = ref.watch(sessionManagerProvider);
    final showSaved = widget.dept != null && sm.isSavedItemsEnabled();

    return Scaffold(
      appBar: orderAppBar(
          subtitle: parts.first,
          third: parts.length > 1 ? parts[1] : null,
          height: parts.length > 1 ? 80 : 72),
      bottomNavigationBar: _BottomBar(
        onBack: () => context.pop(),
        viewing: 'VIEWING 1 to ${_items.length} OF ${_items.length}',
        onSaved: showSaved
            ? () => context.push(
                '${Routes.manageSavedItems}?dept=${Uri.encodeComponent(widget.dept!)}')
            : null,
      ),
      body: Column(
        children: [
          _filterField(primary),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? const Center(
                        child: Text('No items found for this filter.',
                            style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: _items.length,
                        itemBuilder: (_, i) => CatalogItemTile(
                          item: _items[i],
                          onTap: () =>
                              context.push(Routes.itemDetail, extra: _items[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filterField(Color primary) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: TextField(
          onChanged: _onFilter,
          decoration: InputDecoration(
            hintText: 'filter',
            prefixIcon: Icon(Icons.filter_list, color: primary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            isDense: true,
          ),
        ),
      );
}

class _BottomBar extends StatelessWidget {
  final VoidCallback onBack;
  final String viewing;
  final VoidCallback? onSaved;
  const _BottomBar(
      {required this.onBack, required this.viewing, this.onSaved});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      color: primary,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4),
            alignment: Alignment.center,
            child: Text(viewing,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: onBack,
                  child: Row(children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2)),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 10),
                    const Text('BACK',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ]),
                ),
                if (onSaved != null)
                  InkWell(
                    onTap: onSaved,
                    child: Row(children: [
                      const Text('MANAGE SAVED\nITEMS',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                      const SizedBox(width: 10),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: Colors.white),
                        child: Icon(Icons.settings, color: primary, size: 20),
                      ),
                    ]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
