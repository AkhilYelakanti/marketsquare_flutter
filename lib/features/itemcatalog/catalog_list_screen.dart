import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db/item_repository.dart';
import '../../router/app_routes.dart';
import '../orderentry/order_widgets.dart';

/// Generic distinct-value list for a catalog filter dimension
/// (`kind` = DEPT | CS | NEILSON). Tapping a value opens the filtered item list.
class CatalogListScreen extends ConsumerStatefulWidget {
  final String kind;
  final String title;
  const CatalogListScreen({super.key, required this.kind, required this.title});

  @override
  ConsumerState<CatalogListScreen> createState() => _State();
}

class _State extends ConsumerState<CatalogListScreen> {
  final _repo = ItemRepository();
  String _filter = '';
  bool _loading = true;
  List<String> _values = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final v = await _repo.distinctForKind(widget.kind);
    if (mounted) {
      setState(() {
        _values = v;
        _loading = false;
      });
    }
  }

  String _destFor(String value) {
    switch (widget.kind) {
      case 'DEPT':
        return '${Routes.itemFilteredList}?dept=${Uri.encodeComponent(value)}';
      case 'CS':
        return '${Routes.itemFilteredList}?catKind=CS&cat=${Uri.encodeComponent(value)}';
      case 'NEILSON':
        return '${Routes.itemFilteredList}?catKind=NEILSON&cat=${Uri.encodeComponent(value)}';
      default:
        return Routes.itemFilteredList;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final q = _filter.trim().toLowerCase();
    final shown = q.isEmpty
        ? _values
        : _values.where((v) => v.toLowerCase().contains(q)).toList();

    return Scaffold(
      appBar: orderAppBar(subtitle: widget.title, third: '${_values.length} total', height: 72),
      bottomNavigationBar: OrderBottomBar(onBack: () => context.pop()),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _values.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No values found.\n(Load a catalog via Refresh Data.)',
                        textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: TextField(
                        onChanged: (v) => setState(() => _filter = v),
                        decoration: InputDecoration(
                          hintText: 'Filter',
                          prefixIcon: Icon(Icons.filter_list, color: primary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          isDense: true,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        itemCount: shown.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 0.5, color: Color(0xFFEEEEEE)),
                        itemBuilder: (_, i) => ListTile(
                          title: Text(shown[i],
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          trailing: const Icon(Icons.keyboard_arrow_right),
                          onTap: () => context.push(_destFor(shown[i])),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
