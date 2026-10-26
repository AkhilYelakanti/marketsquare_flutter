import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/order_models.dart';
import '../../data/service/image_download_service.dart';
import '../../data/session/session_providers.dart';
import '../../router/app_routes.dart';
import '../datasync/item_refresh_service.dart';
import 'order_entry_controller.dart';
import 'order_widgets.dart';

/// Port of native `SelectCustomerScreen`: searchable store list → select → order
/// type. (Native also re-fetches per-store LOV1 config + offers image download;
/// that refresh is a follow-up tied to the Data Sync module.)
class SelectCustomerScreen extends ConsumerStatefulWidget {
  const SelectCustomerScreen({super.key});

  @override
  ConsumerState<SelectCustomerScreen> createState() =>
      _SelectCustomerScreenState();
}

class _SelectCustomerScreenState extends ConsumerState<SelectCustomerScreen> {
  String _search = '';
  bool _downloading = false;
  String _status = '';

  /// Native parity: after picking a customer, offer the image download
  /// (NOW/LATER → YES/NO) when LOV imageLovConfig enables it, then continue to
  /// order type.
  Future<void> _onCustomer(CustomerEntry c) async {
    ref.read(orderEntryControllerProvider.notifier).selectCustomer(c);
    final sm = ref.read(sessionManagerProvider);
    if (!sm.isImagesEnabled()) {
      _goOrderType();
      return;
    }
    final now = await _askDownload(sm.getImagesTimeToRefresh());
    if (!mounted) return;
    if (now != true) {
      _goOrderType();
      return;
    }
    final yes = await _confirmDownload();
    if (!mounted) return;
    if (yes != true) {
      _goOrderType();
      return;
    }
    await _runDownload();
    if (mounted) _goOrderType();
  }

  void _goOrderType() {
    if (mounted) context.push(Routes.selectOrderType);
  }

  Future<bool?> _askDownload(int minutes) {
    final timeText = minutes > 0
        ? 'approximately $minutes minute${minutes != 1 ? 's' : ''}'
        : 'some time';
    return showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('Download Images'),
        content: Text('Would you like to retrieve item images?\n\nIt will take $timeText.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx, false), child: const Text('LATER')),
          TextButton(
              onPressed: () => Navigator.pop(dctx, true), child: const Text('NOW')),
        ],
      ),
    );
  }

  Future<bool?> _confirmDownload() {
    return showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('Confirm Image Download'),
        content: const Text('Download images now?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx, false), child: const Text('NO')),
          TextButton(
              onPressed: () => Navigator.pop(dctx, true), child: const Text('YES')),
        ],
      ),
    );
  }

  Future<void> _runDownload() async {
    setState(() {
      _downloading = true;
      _status = 'Starting image download...';
    });
    await ref
        .read(imageDownloadServiceProvider)
        .executeDownload((m) => mounted ? setState(() => _status = m) : null);
    if (mounted) setState(() => _downloading = false);
  }

  @override
  void initState() {
    super.initState();
    // On order-entry enter (native parity): re-fetch the LOV1 config so the
    // customer list / buttons / tiles are current even if the post-login sync
    // missed it, then run a non-blocking delta inventory refresh.
    Future.microtask(() async {
      final svc = ref.read(itemRefreshServiceProvider);
      final ok = await svc.refreshLov1();
      if (ok && mounted) {
        ref.read(orderEntryControllerProvider.notifier).loadConfig();
      }
      await svc.runDeltaInventoryRefresh((_) {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final st = ref.watch(orderEntryControllerProvider);

    final q = _search.trim().toLowerCase();
    final filtered = q.isEmpty
        ? st.config.customers
        : st.config.customers.where((c) {
            return c.storeId.toLowerCase().contains(q) ||
                c.storeName.toLowerCase().contains(q);
          }).toList();

    return Scaffold(
      appBar: orderAppBar(subtitle: 'SELECT CUSTOMER'),
      bottomNavigationBar: OrderBottomBar(onBack: () => context.go(Routes.dashboard)),
      body: Stack(
        children: [
          _list(primary, filtered),
          if (_downloading)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                          width: 60,
                          height: 60,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 5)),
                      const SizedBox(height: 18),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(_status,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 6),
                      const Text('please wait...',
                          style: TextStyle(color: Colors.white, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _list(Color primary, List<CustomerEntry> filtered) {
    return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search store ID or name',
                prefixIcon: Icon(Icons.search, color: primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No customers found.\nCheck LOV1 customer config.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 0.5, color: Color(0xFFEEEEEE)),
                    itemBuilder: (_, i) {
                      final c = filtered[i];
                      return _CustomerRow(
                        customer: c,
                        onTap: () => _onCustomer(c),
                      );
                    },
                  ),
          ),
        ],
    );
  }
}

class _CustomerRow extends StatelessWidget {
  final CustomerEntry customer;
  final VoidCallback onTap;
  const _CustomerRow({required this.customer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primary.withValues(alpha: 0.12),
              ),
              child: Icon(Icons.store, color: primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(customer.storeId,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black)),
                  if (customer.storeName.isNotEmpty)
                    Text(customer.storeName,
                        style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
