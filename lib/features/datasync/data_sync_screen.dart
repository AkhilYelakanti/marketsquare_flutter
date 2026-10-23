import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/constants.dart';
import '../../data/session/session_providers.dart';
import '../../router/app_routes.dart';
import '../../widgets/brand_logo.dart';
import 'item_refresh_service.dart';

/// Port of native `DataSyncScreen`: runs the item-file refresh on entry (via
/// ItemRefreshService), then routes on to the dashboard (or rep store
/// selection). Fail-soft — a missing endpoint or error still advances.
///
/// Visual parity with native: brand-primary background, "MS ORDERING" top bar,
/// a large brand logo while syncing, and the app version + progress message
/// pinned to the bottom bar.
class DataSyncScreen extends ConsumerStatefulWidget {
  const DataSyncScreen({super.key});

  @override
  ConsumerState<DataSyncScreen> createState() => _DataSyncScreenState();
}

class _DataSyncScreenState extends ConsumerState<DataSyncScreen> {
  String _message = 'Initializing data...';
  String _version = '';
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() {
      _version = info.version;
      _syncing = true;
    });

    final service = ref.read(itemRefreshServiceProvider);
    await service.runFullRefresh((m) {
      if (mounted) setState(() => _message = m);
    });
    if (!mounted) return;
    final sm = ref.read(sessionManagerProvider);
    final dest = (sm.isRepAccount() && sm.getRepSelectedStoreId() == null)
        ? Routes.chooseActiveCustomer
        : Routes.dashboard;
    context.go(dest);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: primary,
      appBar: AppBar(
        title: const Text(AppConstants.appTitle),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: _syncing
            ? const BrandLogo(size: 200)
            : const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text('Starting data sync...',
                      style: TextStyle(color: Colors.white)),
                ],
              ),
      ),
      bottomNavigationBar: Container(
        color: primary,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_version.isNotEmpty)
              Text(_version, style: const TextStyle(color: Colors.white)),
            Text(_message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
