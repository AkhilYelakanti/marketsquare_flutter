import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/session/session_providers.dart';
import '../orderentry/order_widgets.dart';

/// Port of native `DebugScreen`: session/app info + debug-logging toggle.
/// (Native also shows FileLogger output; file logging is a follow-up.)
class DebugScreen extends ConsumerStatefulWidget {
  const DebugScreen({super.key});

  @override
  ConsumerState<DebugScreen> createState() => _State();
}

class _State extends ConsumerState<DebugScreen> {
  @override
  Widget build(BuildContext context) {
    final sm = ref.watch(sessionManagerProvider);
    final debugOn = sm.isDebugLoggingEnabled();
    final info = {
      'User': sm.getUserId() ?? '—',
      'Store': sm.getStoreId() ?? '—',
      'BU': sm.getBuId() ?? '—',
      'Host': sm.getHostId() ?? '—',
      'Active store': sm.getActiveStoreId(),
      'Auth token': (sm.getAuthToken() ?? '').isEmpty ? 'none' : 'present',
      'Service URLs': '${sm.getAllServiceUrlKeys().length} configured',
      'Last refresh': sm.getRefreshDate() ?? '—',
    };

    return Scaffold(
      appBar: orderAppBar(subtitle: 'DEBUG', height: 60),
      bottomNavigationBar: OrderBottomBar(onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Debug logging'),
            value: debugOn,
            onChanged: (v) async {
              await sm.saveDebugLoggingEnabled(v);
              setState(() {});
            },
          ),
          const Divider(),
          for (final e in info.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                      width: 120,
                      child: Text(e.key,
                          style: const TextStyle(color: Colors.black54, fontSize: 13))),
                  Expanded(child: Text(e.value, style: const TextStyle(fontSize: 13))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
