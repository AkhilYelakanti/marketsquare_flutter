import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../data/session/session_manager.dart';
import '../../data/session/session_providers.dart';
import '../../router/app_routes.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/network_status_action.dart';
import '../datasync/item_refresh_service.dart';
import '../orderentry/order_widgets.dart';

/// Port of native `ChooseActiveCustomerScreen` (rep "Change Store"): a
/// searchable list of the rep's customers (from LOV1 `storeNumbers`). Selecting
/// one saves it as the active store, runs a full item refresh (progress
/// overlay), then returns to the dashboard.
class ChooseActiveCustomerScreen extends ConsumerStatefulWidget {
  const ChooseActiveCustomerScreen({super.key});

  @override
  ConsumerState<ChooseActiveCustomerScreen> createState() => _State();
}

class _State extends ConsumerState<ChooseActiveCustomerScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  bool _selecting = false;
  String _progress = 'Loading store configuration...';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _select(CustomerEntry c) async {
    if (_selecting) return;
    setState(() {
      _selecting = true;
      _progress = 'Loading store configuration...';
    });
    final sm = ref.read(sessionManagerProvider);
    await sm.saveRepSelectedCustomer(c.storeId, c.storeName);
    await ref.read(itemRefreshServiceProvider).runFullRefresh((m) {
      if (mounted) setState(() => _progress = m);
    });
    if (!mounted) return;
    context.go(Routes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final all = ref.watch(sessionManagerProvider).getStoreNumbers();
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? all
        : all
            .where((c) =>
                c.storeId.toLowerCase().contains(q) ||
                c.storeName.toLowerCase().contains(q))
            .toList();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        automaticallyImplyLeading: false,
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            BrandLogo(size: 36),
            Text('OPTIONS',
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(AppConstants.appTitle,
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            Text('CHOOSE ACTIVE CUSTOMER',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: const [NetworkStatusAction()],
      ),
      // BACK: to the dashboard if a store is already active (reached from Change
      // Store), otherwise back to login (switch user) — never trap the user here.
      bottomNavigationBar: OrderBottomBar(
        onBack: () {
          final hasStore =
              ref.read(sessionManagerProvider).getRepSelectedStoreId() != null;
          context.go(hasStore ? Routes.dashboard : Routes.login);
        },
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'filter customers...',
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
                            'No customers found.\nCheck LOV1 storeNumbers config.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 0.5, color: Color(0xFFEEEEEE)),
                        itemBuilder: (_, i) => _row(filtered[i], primary),
                      ),
              ),
            ],
          ),
          if (_selecting)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 56,
                        height: 56,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 5),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(_progress,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(CustomerEntry c, Color primary) {
    return InkWell(
      onTap: () => _select(c),
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
              alignment: Alignment.center,
              child: Icon(Icons.store, color: primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.storeId,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black)),
                  if (c.storeName.isNotEmpty)
                    Text(c.storeName,
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
