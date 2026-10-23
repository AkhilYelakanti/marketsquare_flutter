import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_routes.dart';
import '../../widgets/hardware_scan_listener.dart';
import 'order_entry_controller.dart';
import 'order_widgets.dart';
import 'tile_widgets.dart';

/// Port of native `OrderItemSearchScreen` ("SEARCH ALL"). Debounced text search
/// (>= 3 chars) against the item catalog; each result has qty +/- that adds to
/// the order. Native renders catalog tile cards + the alert pipeline — those
/// ride on the item-catalog module. Results are empty until Data Sync populates
/// the items table.
class OrderItemSearchScreen extends ConsumerStatefulWidget {
  const OrderItemSearchScreen({super.key});

  @override
  ConsumerState<OrderItemSearchScreen> createState() => _State();
}

class _State extends ConsumerState<OrderItemSearchScreen> {
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
    final items = await ref.read(itemRepositoryProvider).searchAll(q);
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
    final subtitle = _loading
        ? 'Searching…'
        : (_query.trim().length < 3
            ? 'Type at least 3 characters to search'
            : (_results.isNotEmpty ? '${_results.length} result(s)' : 'No results found'));

    return Scaffold(
      appBar: orderAppBar(subtitle: 'SEARCH ALL', third: subtitle, height: 84),
      bottomNavigationBar: OrderBottomBar(onBack: () => context.pop()),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: TextField(
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: 'key a search string',
                prefixIcon: Icon(Icons.search, color: primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
            ),
          ),
          Expanded(child: _body(context)),
          const OrderAlertHost(),
          HardwareScanListener(onScan: _onHardwareScan),
        ],
      ),
    );
  }

  Future<void> _onHardwareScan(String code) async {
    final matches = await ref.read(itemRepositoryProvider).queryByExactCode(code);
    if (!mounted) return;
    final ctrl = ref.read(orderEntryControllerProvider.notifier);
    if (matches.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$code not found')));
    } else if (matches.length == 1) {
      ctrl.commitItem(matches.first, '1');
    } else {
      ctrl.setMults(code, matches);
      context.push(Routes.orderMultsReturned);
    }
  }

  Widget _body(BuildContext context) {
    if (_query.trim().length < 3) {
      return const _Empty('Enter at least 3 characters\nto start searching.');
    }
    if (_loading && _results.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_results.isEmpty) {
      return const _Empty(
          'No items found.\n(The catalog is populated by Data Sync, not yet ported.)');
    }
    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (_, i) => OrderItemTile(item: _results[i]),
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
