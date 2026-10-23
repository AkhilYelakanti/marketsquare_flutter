import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../data/session/session_providers.dart';
import '../../router/app_routes.dart';
import '../orderentry/order_widgets.dart';

final _versionProvider =
    FutureProvider.autoDispose((ref) async => (await PackageInfo.fromPlatform()).version);

/// Port of native `HelpScreen`: menu + support contact + version.
class HelpScreen extends ConsumerWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = Theme.of(context).colorScheme.primary;
    final sm = ref.watch(sessionManagerProvider);
    final email = sm.getSupportEmail();
    final phone = sm.getSupportPhone();
    final version = ref.watch(_versionProvider).maybeWhen(data: (v) => v, orElse: () => '');

    return Scaffold(
      appBar: orderAppBar(subtitle: 'HELP', height: 60),
      bottomNavigationBar: OrderBottomBar(onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _item(context, primary, Icons.menu_book, 'Operational Guide', Routes.operationalGuide),
          _item(context, primary, Icons.qr_code_scanner, 'Scan Debug', Routes.scanDebug),
          _item(context, primary, Icons.bug_report, 'Debug', Routes.debug),
          const Divider(height: 28),
          const Text('Support', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          ListTile(
            dense: true,
            leading: Icon(Icons.email, color: primary),
            title: Text(email.isEmpty ? 'Support email not configured' : email),
          ),
          ListTile(
            dense: true,
            leading: Icon(Icons.phone, color: primary),
            title: Text(phone.isEmpty ? 'Support phone not configured' : phone),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text('Version $version',
                style: const TextStyle(color: Colors.black45, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, Color primary, IconData icon, String title, String route) {
    return Card(
      color: const Color(0xFFE0E0E0),
      child: ListTile(
        leading: Icon(icon, color: primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(route),
      ),
    );
  }
}
