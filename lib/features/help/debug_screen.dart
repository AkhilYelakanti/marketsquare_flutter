import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/device_meta.dart';
import '../../core/network/api_log.dart';
import '../../data/repository/data_sync_repository.dart';
import '../../data/session/session_providers.dart';
import '../orderentry/order_widgets.dart';

/// Port of native `DebugScreen` + `HelpViewModel.sendConfiguration`.
///
/// Shows the in-memory REST call trace (request URL/body + response for
/// JSON/text calls — binary file downloads are never captured), a debug-logging
/// toggle, and RESET LOG / SHOW PATH / SEND CONFIGURATION actions.
class DebugScreen extends ConsumerStatefulWidget {
  const DebugScreen({super.key});

  @override
  ConsumerState<DebugScreen> createState() => _State();
}

class _State extends ConsumerState<DebugScreen> {
  bool _showPath = false;
  bool _sending = false;

  String _logText() {
    final entries = ApiLog.entries;
    if (entries.isEmpty) return 'No REST calls logged yet.';
    final b = StringBuffer();
    // Latest first.
    for (final e in entries.reversed) {
      final t = e.time.toIso8601String().substring(11, 19);
      b.writeln('[$t] ROUTE: ${e.route}');
      if (e.body.isNotEmpty) b.writeln('REQUEST:\n${e.body}');
      b.writeln('RESPONSE:\n${e.resp}');
      b.writeln('─' * 40);
    }
    return b.toString();
  }

  Future<void> _sendConfiguration() async {
    final sm = ref.read(sessionManagerProvider);
    final url = sm.getServiceUrl(AppConstants.serviceKeySendConfig);
    final token = sm.getAuthToken();
    if (url == null || url.isEmpty) {
      _toast('SEND_CONFIG URL not configured');
      return;
    }
    if (token == null || token.isEmpty) {
      _toast('Not authenticated');
      return;
    }
    setState(() => _sending = true);
    try {
      final dev = await deviceId();
      final ver = await versionId();
      final urlMap = {
        for (final k in sm.getAllServiceUrlKeys()) k: sm.getServiceUrl(k) ?? '',
      };
      final payload = <String, dynamic>{
        'deviceId': dev,
        'storeId': sm.getStoreId() ?? '',
        'userId': sm.getUserId() ?? '',
        'buId': sm.getBuId() ?? '',
        'hostId': sm.getHostId() ?? '',
        'serviceId': sm.getServiceId() ?? '',
        'versionId': ver,
        'brandLogoUrl': sm.getBrandLogoUrl() ?? '',
        'brandBackgroundColor': sm.getBrandBackgroundColor() ?? '',
        'serviceUrlMap': urlMap,
        'debugLoggingEnabled': ApiLog.enabled,
      };
      final res = await DataSyncRepository().postText(url, token, payload);
      if (!mounted) return;
      _toast(res.isSuccess
          ? 'Configuration sent successfully'
          : 'Failed: ${res.error}');
    } catch (e) {
      if (mounted) _toast('Error: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final sm = ref.watch(sessionManagerProvider);
    final primary = Theme.of(context).colorScheme.primary;
    final pathSummary = <String, String>{
      'User': sm.getUserId() ?? '—',
      'Store': sm.getStoreId() ?? '—',
      'Active store': sm.getActiveStoreId(),
      'BU': sm.getBuId() ?? '—',
      'Host': sm.getHostId() ?? '—',
      'Service URLs': '${sm.getAllServiceUrlKeys().length} configured',
      'Scan params': '${sm.getScanParams().length}',
      'Auth token': (sm.getAuthToken() ?? '').isEmpty ? 'none' : 'present',
      'Last refresh': sm.getRefreshDate() ?? '—',
    };

    return Scaffold(
      appBar: orderAppBar(subtitle: 'DEBUG', height: 60),
      bottomNavigationBar: OrderBottomBar(onBack: () => context.pop()),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Debug Logging Enabled',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                Switch(
                  value: ApiLog.enabled,
                  onChanged: (v) async {
                    await sm.saveDebugLoggingEnabled(v);
                    setState(() => ApiLog.enabled = v);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    _logText(),
                    style: const TextStyle(
                        fontSize: 11,
                        height: 1.5,
                        fontFamily: 'monospace',
                        color: Colors.black87),
                  ),
                ),
              ),
            ),
            if (_showPath) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SelectableText(
                  const JsonEncoder.withIndent('  ').convert(pathSummary),
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _btn('SHOW PATH', primary,
                      () => setState(() => _showPath = !_showPath)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _btn('RESET LOG', primary, () {
                    ApiLog.clear();
                    setState(() => _showPath = false);
                  }),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _btn(_sending ? 'SENDING…' : 'SEND CONFIGURATION', primary,
                _sending ? null : _sendConfiguration),
          ],
        ),
      ),
    );
  }

  Widget _btn(String text, Color color, VoidCallback? onTap) => SizedBox(
        height: 48,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(2))),
          ),
          child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
}
