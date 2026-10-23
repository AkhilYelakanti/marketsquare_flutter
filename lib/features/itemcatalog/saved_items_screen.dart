import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/device_meta.dart';
import '../../data/db/item_repository.dart';
import '../../data/repository/data_sync_repository.dart';
import '../../data/session/session_providers.dart';
import '../../router/app_routes.dart';
import '../orderentry/order_widgets.dart';
import 'catalog_tile.dart';

/// Port of native `ManageSavedItemsScreen`: every item in the chosen department
/// with a checkbox for saved status. CLEAR removes all saved items for the
/// department; UPDATE SAVED ITEMS persists the current selection to the server.
class SavedItemsScreen extends ConsumerStatefulWidget {
  final String dept;
  const SavedItemsScreen({super.key, this.dept = ''});

  @override
  ConsumerState<SavedItemsScreen> createState() => _State();
}

class _State extends ConsumerState<SavedItemsScreen> {
  final _repo = ItemRepository();
  final _sync = DataSyncRepository();
  bool _loading = true;
  bool _busy = false;
  String _filter = '';
  Timer? _debounce;
  List<Map<String, String>> _items = [];
  Set<String> _saved = {};

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
    final sm = ref.read(sessionManagerProvider);
    final items = await _repo.queryItems(dept: widget.dept.isEmpty ? null : widget.dept);
    // Server saved codes (best-effort) with local fallback.
    var saved = sm.getSavedItemCodes();
    final serverCodes = await _fetchServerSaved();
    if (serverCodes != null) {
      saved = serverCodes;
      await sm.saveSavedItemCodes(saved);
    }
    if (mounted) {
      setState(() {
        _items = items;
        _saved = {...saved};
        _loading = false;
      });
    }
  }

  String _codeOf(Map<String, String> it) => (it[ItemRepository.colItem] ?? '').trim();

  Future<Set<String>?> _fetchServerSaved() async {
    final sm = ref.read(sessionManagerProvider);
    final url = sm.getServiceUrl('STORE_SAVED_ITEMS');
    final token = sm.getAuthToken();
    if (url == null || url.isEmpty || token == null || token.isEmpty) return null;
    final res = await _sync.postText(url, token, await _header());
    if (!res.isSuccess) return null;
    try {
      final obj = jsonDecode(res.value!) as Map<String, dynamic>;
      final list = (obj['itemList'] as List?) ?? const [];
      return list
          .map((e) => (e is Map ? (e['itemNumber'] ?? '') : '').toString().trim())
          .where((s) => s.isNotEmpty)
          .toSet();
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> _header() async {
    final sm = ref.read(sessionManagerProvider);
    return {
      'deviceId': await deviceId(),
      'storeId': sm.getActiveStoreId(),
      'userName': sm.getUserId() ?? '',
      'versionId': await versionId(),
      'storeDepartment': widget.dept,
    };
  }

  void _toggle(String code) {
    if (code.isEmpty) return;
    setState(() {
      if (_saved.contains(code)) {
        _saved.remove(code);
      } else {
        _saved.add(code);
      }
    });
  }

  Future<void> _update() async {
    final sm = ref.read(sessionManagerProvider);
    await sm.saveSavedItemCodes(_saved);
    final url = sm.getServiceUrl('UPDATE_SAVED_ITEMS');
    final token = sm.getAuthToken();
    if (url == null || url.isEmpty || token == null || token.isEmpty) {
      _toast('Saved locally (no server URL).');
      return;
    }
    setState(() => _busy = true);
    final checked = _items
        .map(_codeOf)
        .where((c) => c.isNotEmpty && _saved.contains(c))
        .toList();
    final payload = {
      'header': await _header(),
      'itemList':
          checked.map((c) => {'itemNumber': c, 'storeDepartment': widget.dept}).toList(),
    };
    final res = await _sync.postText(url, token, payload);
    if (!mounted) return;
    setState(() => _busy = false);
    _toast(res.isSuccess ? 'Saved items updated.' : 'Update failed: ${res.error}');
  }

  Future<void> _clear() async {
    final sm = ref.read(sessionManagerProvider);
    final deptCodes = _items.map(_codeOf).where((c) => c.isNotEmpty).toSet();
    setState(() => _saved.removeAll(deptCodes));
    await sm.saveSavedItemCodes(_saved);
    final url = sm.getServiceUrl('CLEAR_SAVED_ITEMS');
    final token = sm.getAuthToken();
    if (url != null && url.isNotEmpty && token != null && token.isNotEmpty) {
      setState(() => _busy = true);
      await _sync.postText(url, token, await _header());
      if (mounted) setState(() => _busy = false);
    }
    _toast('Saved items cleared for ${widget.dept}.');
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final sm = ref.watch(sessionManagerProvider);
    final store = sm.getActiveStoreId();
    final q = _filter.trim().toLowerCase();
    final shown = q.isEmpty
        ? _items
        : _items.where((it) {
            final d = (it[ItemRepository.colDesc] ?? '').toLowerCase();
            final n = _codeOf(it).toLowerCase();
            return d.contains(q) || n.contains(q);
          }).toList();

    return Scaffold(
      appBar: orderAppBar(
          subtitle: '$store - ${widget.dept}',
          third: 'SAVED ITEMS',
          height: 80),
      bottomNavigationBar: _BottomBar(
        viewing: 'VIEWING ${_items.length} ITEMS',
        onBack: () => context.pop(),
        onClear: _busy ? null : _clear,
        onUpdate: _busy ? null : _update,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: TextField(
                  onChanged: (v) {
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 250),
                        () => setState(() => _filter = v));
                  },
                  decoration: InputDecoration(
                    hintText: 'filter',
                    prefixIcon: Icon(Icons.filter_list, color: primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                  ),
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : shown.isEmpty
                        ? const Center(
                            child: Text('No items in this department.',
                                style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            itemCount: shown.length,
                            itemBuilder: (_, i) {
                              final code = _codeOf(shown[i]);
                              return CatalogItemTile(
                                item: shown[i],
                                checked: _saved.contains(code),
                                onToggleChecked: () => _toggle(code),
                                onTap: () =>
                                    context.push(Routes.itemDetail, extra: shown[i]),
                              );
                            },
                          ),
              ),
            ],
          ),
          if (_busy)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.black38,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final String viewing;
  final VoidCallback onBack;
  final VoidCallback? onClear;
  final VoidCallback? onUpdate;
  const _BottomBar(
      {required this.viewing,
      required this.onBack,
      this.onClear,
      this.onUpdate});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    Widget circleAction(String label, IconData icon, VoidCallback? onTap,
            {bool labelLeft = false}) =>
        InkWell(
          onTap: onTap,
          child: Row(
            children: [
              if (labelLeft) ...[
                Text(label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(width: 8),
              ],
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: Colors.white),
                child: Icon(icon, color: primary, size: 20),
              ),
              if (!labelLeft) ...[
                const SizedBox(width: 8),
                Text(label,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ],
          ),
        );

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
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                circleAction('BACK', Icons.arrow_back, onBack),
                circleAction('CLEAR', Icons.close, onClear),
                circleAction('UPDATE SAVED\nITEMS', Icons.redo, onUpdate,
                    labelLeft: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
