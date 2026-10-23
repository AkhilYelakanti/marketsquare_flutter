import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db/item_repository.dart';
import '../../router/app_routes.dart';

/// Port of native `ItemSearchScreen` (catalog SEARCH ALL): debounced search of
/// the item table; tap a row to view its detail.
class ItemSearchScreen extends ConsumerStatefulWidget {
  const ItemSearchScreen({super.key});

  @override
  ConsumerState<ItemSearchScreen> createState() => _State();
}

class _State extends ConsumerState<ItemSearchScreen> {
  final _repo = ItemRepository();
  String _query = '';
  bool _loading = false;
  List<Map<String, String>> _results = [];
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String v) {
    setState(() => _query = v);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _run(v));
  }

  Future<void> _run(String q) async {
    if (q.trim().length < 3) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);
    final items = await _repo.searchAll(q);
    if (mounted) {
      setState(() {
        _results = items;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(title: const Text('SEARCH ALL ITEMS')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              autofocus: true,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: 'key a search string',
                prefixIcon: Icon(Icons.search, color: primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
            ),
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_query.trim().length < 3) {
      return const _Empty('Enter at least 3 characters to search.');
    }
    if (_loading && _results.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_results.isEmpty) {
      return const _Empty(
          'No items found.\n(Load a catalog via Refresh Data if empty.)');
    }
    return ListView.separated(
      itemCount: _results.length,
      separatorBuilder: (_, _) => const Divider(height: 0.5, color: Color(0xFFEEEEEE)),
      itemBuilder: (_, i) {
        final item = _results[i];
        final number = item[ItemRepository.colItem] ?? '';
        final desc = item[ItemRepository.colDesc] ?? '';
        final dept = item[ItemRepository.colDept] ?? '';
        return ListTile(
          title: Text(desc.isEmpty ? number : desc,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('# $number${dept.isNotEmpty ? '  •  $dept' : ''}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(Routes.itemDetail, extra: item),
        );
      },
    );
  }
}

class _Empty extends StatelessWidget {
  final String text;
  const _Empty(this.text);
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(text,
              textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
        ),
      );
}
