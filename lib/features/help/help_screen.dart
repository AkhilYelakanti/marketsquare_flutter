import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../data/session/session_providers.dart';
import '../../router/app_routes.dart';
import '../orderentry/order_widgets.dart';

final _versionProvider =
    FutureProvider.autoDispose((ref) async => (await PackageInfo.fromPlatform()).version);

/// Port of native `HelpScreen`: version, EMAIL + CALL support cards, and the
/// OPERATIONAL GUIDE / SCAN DEBUGGING / DEBUG menu tiles — brand circle icons on
/// grey cards.
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
      appBar: orderAppBar(subtitle: 'HELP', height: 64),
      bottomNavigationBar: OrderBottomBar(onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('version  $version',
                  style: const TextStyle(
                      color: Colors.black54, fontWeight: FontWeight.w600, fontSize: 14)),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _ContactCard(
                  primary: primary,
                  icon: Icons.alternate_email,
                  title: 'EMAIL',
                  detail: email,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ContactCard(
                  primary: primary,
                  icon: Icons.headset_mic,
                  title: 'CALL',
                  detail: phone.isEmpty ? '—' : phone,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _MenuTile(
              primary: primary,
              icon: Icons.description,
              title: 'OPERATIONAL GUIDE',
              onTap: () => context.push(Routes.operationalGuide)),
          const SizedBox(height: 10),
          _MenuTile(
              primary: primary,
              icon: Icons.qr_code_scanner,
              title: 'SCAN DEBUGGING',
              onTap: () => context.push(Routes.scanDebug)),
          const SizedBox(height: 10),
          _MenuTile(
              primary: primary,
              icon: Icons.settings,
              title: 'DEBUG',
              onTap: () => context.push(Routes.debug)),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final Color primary;
  final IconData icon;
  final String title;
  final String detail;
  const _ContactCard(
      {required this.primary,
      required this.icon,
      required this.title,
      required this.detail});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFE2E2E2),
      shape: const RoundedRectangleBorder(),
      child: SizedBox(
        height: 120,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 12)),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: primary, width: 3),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: primary, size: 26),
              ),
              Text(detail,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF2A4EC9), fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final Color primary;
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _MenuTile(
      {required this.primary,
      required this.icon,
      required this.title,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFE2E2E2),
      shape: const RoundedRectangleBorder(),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 90,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: primary, width: 3),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: primary, size: 28),
              ),
              const SizedBox(height: 4),
              Text(title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}
