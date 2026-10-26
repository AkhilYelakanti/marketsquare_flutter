import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../data/service/image_download_service.dart';
import '../../data/session/session_providers.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/network_status_action.dart';
import '../datasync/item_refresh_service.dart';

/// Port of native `RefreshDataScreen`: a REFRESH ITEM FILE card (with the
/// previous-refresh filename/date/record count) and a DOWNLOAD IMAGES card,
/// a costs disclaimer pinned to the bottom, and a full-screen progress overlay
/// while a refresh runs. Brand top bar + blue BACK bar, matching the live CSWG
/// screen.
class RefreshDataScreen extends ConsumerStatefulWidget {
  const RefreshDataScreen({super.key});

  @override
  ConsumerState<RefreshDataScreen> createState() => _State();
}

class _State extends ConsumerState<RefreshDataScreen> {
  bool _busy = false;
  String _status = '';
  String? _result;
  bool _resultError = false;

  Future<void> _refresh() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _result = null;
      _status = 'refreshing item data...';
    });
    final ok = await ref
        .read(itemRefreshServiceProvider)
        .runFullRefresh((m) => setState(() => _status = m));
    if (!mounted) return;
    setState(() {
      _busy = false;
      _resultError = !ok;
      _result = ok ? 'Refresh complete.' : 'Refresh failed.';
    });
  }

  Future<void> _downloadImages() async {
    if (_busy) return;
    final sm = ref.read(sessionManagerProvider);
    if (!sm.isImagesEnabled()) {
      setState(() {
        _result = 'Images are not enabled in configuration.';
        _resultError = true;
      });
      return;
    }
    setState(() {
      _busy = true;
      _result = null;
      _status = 'Starting image download...';
    });
    final res = await ref
        .read(imageDownloadServiceProvider)
        .executeDownload((m) => setState(() => _status = m));
    if (!mounted) return;
    setState(() {
      _busy = false;
      _resultError = !res.ok;
      _result = res.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sm = ref.watch(sessionManagerProvider);
    final primary = Theme.of(context).colorScheme.primary;
    final file = sm.getRefreshFileName();
    final date = sm.getRefreshDate();
    final count = sm.getRefreshRecordCount();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
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
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            Text('REFRESH DATA',
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: const [NetworkStatusAction()],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _refreshCard(primary, file, date, count),
                const SizedBox(height: 8),
                _imagesCard(primary),
                const Spacer(),
                const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text(
                    'Costs are subject to change from the time of order entry to delivery.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF616161)),
                  ),
                ),
              ],
            ),
          ),
          if (_busy) _overlay(),
        ],
      ),
      bottomNavigationBar: Container(
        color: primary,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: InkWell(
          onTap: () => context.canPop() ? context.pop() : null,
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              const Text('BACK',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circleIcon(IconData glyph, Color primary) => Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Icon(glyph, color: Colors.white, size: 26),
      );

  Widget _refreshCard(Color primary, String? file, String? date, String? count) {
    return Card(
      color: const Color(0xFFE0E0E0),
      child: InkWell(
        onTap: _busy ? null : _refresh,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              _circleIcon(Icons.sync, primary),
              const SizedBox(height: 4),
              const Text('REFRESH ITEM FILE',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              if (_result != null) ...[
                const SizedBox(height: 4),
                Text(_result!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 11,
                        color: _resultError ? Colors.red : const Color(0xFF2E7D32))),
              ],
              const SizedBox(height: 4),
              const Text('PREVIOUS REFRESH',
                  style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text(file ?? '—',
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
              Text('DOWNLOADED ${date ?? '—'}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              Text('RECORDS ${count ?? '0'}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagesCard(Color primary) {
    final sm = ref.read(sessionManagerProvider);
    final date = sm.getImageDownloadDate();
    final count = sm.getImageDownloadCount();
    return Card(
      color: const Color(0xFFE0E0E0),
      child: InkWell(
        onTap: _busy ? null : _downloadImages,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              _circleIcon(Icons.photo_library, primary),
              const SizedBox(height: 4),
              const Text('DOWNLOAD IMAGES',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Text('DOWNLOADED ${date ?? '—'}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              Text('IMAGES IN STORE ${count ?? '—'}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _overlay() {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black54,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 5),
              ),
              const SizedBox(height: 20),
              Text(_status,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('please wait...',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}
