import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../data/session/session_providers.dart';
import '../../router/app_routes.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/network_status_action.dart';
import '../messages/message_dialogs.dart';
import '../messages/messages_controller.dart';

class _DashItem {
  final String title;
  final IconData icon;
  final String route;
  final bool wide;
  final bool filled; // true = white glyph on a filled brand circle
  final VoidCallback? onTap; // when set, overrides route navigation (popups)
  const _DashItem(this.title, this.icon, this.route,
      {this.wide = false, this.filled = true, this.onTap});
}

/// Port of native `DashboardScreen` — 2-column grid, order-entry spanning full
/// width, rep vs. non-rep tile swap, brand top bar + grey date footer. Labels
/// are uppercase and icons are white glyphs on filled brand circles, matching
/// the live CSWG dashboard.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = Theme.of(context).colorScheme.primary;
    final sm = ref.watch(sessionManagerProvider);
    final userId = sm.getUserId();
    final isRep = sm.isRepAccount();
    final unread = ref.watch(messagesUnreadProvider).maybeWhen(
          data: (v) => v,
          orElse: () => 0,
        );

    // Mandatory IMPORTANT alert: check on show, pop a dialog when due.
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(messagesControllerProvider.notifier).checkImportant());
    ref.listen(messagesControllerProvider.select((s) => s.importantAlert), (_, cfg) {
      if (cfg != null) showImportantAlertDialog(context, ref, cfg);
    });

    final items = <_DashItem>[
      const _DashItem('ORDER ENTRY', Icons.add, Routes.orderEntry,
          wide: true, filled: false),
      const _DashItem('ITEM CATALOG', Icons.list, Routes.itemCatalog),
      const _DashItem('REVIEW ORDERS', Icons.description, Routes.reviewOrders),
      const _DashItem('REFRESH DATA', Icons.refresh, Routes.refreshData),
      const _DashItem('SEND ORDERS', Icons.send, Routes.sendOrders),
      const _DashItem('USER SETUP', Icons.person, Routes.userSetup),
      if (isRep)
        const _DashItem('CHANGE STORE', Icons.store, Routes.chooseActiveCustomer)
      else
        _DashItem('MESSAGES', Icons.chat_bubble, Routes.messages,
            onTap: () => showMessagesDialog(context)),
      const _DashItem('OTHER OPTIONS', Icons.settings, Routes.otherOptions),
      const _DashItem('HELP', Icons.question_mark, Routes.help),
    ];

    final wide = items.where((i) => i.wide).toList();
    final rest = items.where((i) => !i.wide).toList();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const BrandLogo(size: 36),
            const Text('OPTIONS',
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(AppConstants.appTitle,
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
            const Text('HOME',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
            if (userId != null)
              Text('USER: $userId',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
        actions: const [NetworkStatusAction()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(6),
        child: Column(
          children: [
            for (final w in wide)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _tile(context, w, primary, height: 130),
              ),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1.35,
              children: [
                for (final i in rest)
                  _tile(context, i, primary,
                      badge: i.route == Routes.messages ? unread : 0),
              ],
            ),
          ],
        ),
      ),
      // Grey footer bar with the current date/time (live CSWG parity).
      bottomNavigationBar: Container(
        color: const Color(0xFFE0E0E0),
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        child: Text(
          _now(),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF757575), fontSize: 16),
        ),
      ),
    );
  }

  /// White glyph on a filled brand circle (native custom-icon parity); the wide
  /// Order Entry tile uses an outlined ring instead.
  Widget _tileIcon(_DashItem item, Color primary, {double size = 52}) {
    if (!item.filled) {
      return Icon(Icons.add_circle_outline, color: primary, size: size);
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Icon(item.icon, color: Colors.white, size: size * 0.56),
    );
  }

  Widget _tile(BuildContext context, _DashItem item, Color primary,
      {double? height, int badge = 0}) {
    final icon = _tileIcon(item, primary);
    return SizedBox(
      height: height,
      child: Card(
        color: const Color(0xFFE0E0E0),
        child: InkWell(
          onTap: item.onTap ?? () => context.push(item.route),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                badge > 0
                    ? Badge(
                        label: Text(badge > 99 ? '99+' : '$badge'),
                        child: icon,
                      )
                    : icon,
                const SizedBox(height: 4),
                Text(item.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _now() {
    final d = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour < 12 ? 'AM' : 'PM';
    return '${two(d.month)}/${two(d.day)}/${d.year} ${two(h12)}:${two(d.minute)} $ampm';
  }
}
