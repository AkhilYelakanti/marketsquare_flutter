import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/constants.dart';
import '../../data/session/session_providers.dart';
import '../../router/app_routes.dart';
import '../../widgets/brand_logo.dart';

/// Port of native `SplashScreen`: 2s hold, then route by session state.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _version = info.version);

    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final sm = ref.read(sessionManagerProvider);
    final hasSession = (sm.getAuthToken() ?? '').isNotEmpty &&
        (sm.getUserId() ?? '').isNotEmpty;

    if (hasSession) {
      final dest = (sm.isRepAccount() && sm.getRepSelectedStoreId() == null)
          ? Routes.chooseActiveCustomer
          : Routes.dashboard;
      context.go(dest);
    } else {
      context.go(Routes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const BrandLogo(size: 96),
            const SizedBox(height: 12),
            const Text(AppConstants.appTitle, style: TextStyle(color: Colors.white)),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(_version, style: const TextStyle(color: Colors.white)),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Loading...', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
