import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

import '../../core/constants.dart';
import '../../core/device_meta.dart';
import '../../data/repository/data_sync_repository.dart';
import '../../data/session/session_providers.dart';
import '../orderentry/order_widgets.dart';

/// Port of native `OperationalGuideScreen` + `HelpViewModel.loadManualPdf`:
/// explicitly fetches the operational-manual PDF (OPERATIONAL_MANUAL-MANUAL),
/// caches it to a temp file, and renders it with a paged PDF viewer.
class OperationalGuideScreen extends ConsumerStatefulWidget {
  const OperationalGuideScreen({super.key});

  @override
  ConsumerState<OperationalGuideScreen> createState() => _State();
}

class _State extends ConsumerState<OperationalGuideScreen> {
  PdfController? _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final sm = ref.read(sessionManagerProvider);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/operational_manual.pdf');

      if (!file.existsSync() || file.lengthSync() == 0) {
        final url = sm.getServiceUrl(AppConstants.serviceKeyOperationalManual);
        final token = sm.getAuthToken();
        if (url == null || url.isEmpty) {
          _fail('Operational guide URL not configured.');
          return;
        }
        if (token == null || token.isEmpty) {
          _fail('Not authenticated.');
          return;
        }
        final req = <String, dynamic>{
          'deviceId': await deviceId(),
          'storeId': sm.getStoreId() ?? '',
          'userName': sm.getUserId() ?? '',
          'versionId': await versionId(),
        };
        final res =
            await DataSyncRepository().getOperationalManualPdf(url, token, req);
        if (!res.isSuccess) {
          _fail('Failed to load manual: ${res.error}');
          return;
        }
        await file.writeAsBytes(res.value!, flush: true);
      }

      final controller = PdfController(document: PdfDocument.openFile(file.path));
      if (!mounted) return;
      setState(() {
        _controller = controller;
        _loading = false;
      });
    } catch (e) {
      _fail('Failed to load manual: $e');
    }
  }

  void _fail(String msg) {
    if (!mounted) return;
    setState(() {
      _error = msg;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: orderAppBar(subtitle: 'OPERATIONAL GUIDE', height: 60),
      bottomNavigationBar: OrderBottomBar(onBack: () => context.pop()),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _load,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: primary, foregroundColor: Colors.white),
                          child: const Text('RETRY'),
                        ),
                      ],
                    ),
                  ),
                )
              : PdfView(controller: _controller!),
    );
  }
}
