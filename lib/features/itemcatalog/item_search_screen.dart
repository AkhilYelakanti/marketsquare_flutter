import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db/item_repository.dart';
import '../../data/session/session_providers.dart';
import '../../router/app_routes.dart';
import '../orderentry/order_widgets.dart';
import 'catalog_tile.dart';

/// Catalog SEARCH ALL ITEMS (and SEARCH IMAGES when [imageSearch]): a keyed
/// search of the item table that fires once the query reaches the LOV-configured
/// minimum length. Results render with the default tile config.
class ItemSearchScreen extends ConsumerStatefulWidget {
  final bool imageSearch;
  const ItemSearchScreen({super.key, this.imageSearch = false});

  @override
  ConsumerState<ItemSearchScreen> createState() => _State();
}

class _State extends ConsumerState<ItemSearchScreen> {
  final _repo = ItemRepository();
  final _controller = TextEditingController();
  String _query = '';
  bool _loading = false;
  bool _searched = false;
  List<Map<String, String>> _results = [];
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  int get _minChars => ref.read(sessionManagerProvider).getMinSearchChars();

  void _onChanged(String v) {
    setState(() => _query = v);
    _debounce?.cancel();
    if (v.trim().length < _minChars) {
      setState(() {
        _results = [];
        _searched = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), _run);
  }

  Future<void> _run() async {
    final q = _query.trim();
    if (q.length < _minChars) return;
    setState(() => _loading = true);
    final items = await _repo.queryItems(search: q, imageSearch: widget.imageSearch);
    if (mounted) {
      setState(() {
        _results = items;
        _loading = false;
        _searched = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: orderAppBar(
          subtitle: widget.imageSearch ? 'SEARCH IMAGES' : 'SEARCH ALL ITEMS',
          height: 60),
      bottomNavigationBar: OrderBottomBar(onBack: () => context.pop()),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    onChanged: _onChanged,
                    onSubmitted: (_) => _run(),
                    decoration: const InputDecoration(
                      hintText: 'key a search string',
                      border: UnderlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _run,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primary,
                      border: Border.all(color: primary, width: 2),
                    ),
                    child: const Icon(Icons.search, color: Colors.white, size: 26),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_query.trim().length < _minChars) {
      return _Empty('Enter at least $_minChars characters to search.');
    }
    if (_loading && _results.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_searched && _results.isEmpty) {
      return const _Empty('No items found.');
    }
    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (_, i) => CatalogItemTile(
        item: _results[i],
        onTap: () => context.push(Routes.itemDetail, extra: _results[i]),
      ),
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
