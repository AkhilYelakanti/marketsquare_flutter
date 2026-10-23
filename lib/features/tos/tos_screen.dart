import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/device_meta.dart';
import '../../data/session/session_providers.dart';
import '../../router/app_routes.dart';
import '../../widgets/brand_logo.dart';
import 'tos_repository.dart';

final tosRepositoryProvider = Provider<TosRepository>(
  (ref) => TosRepository(ref.watch(apiClientProvider)),
);

enum _Phase { loading, requires, accepting, error }

/// Port of native `TOSScreen`: fetches the pending terms from the backend
/// (`TERMS_MESSAGE-TERMS`), shows them with a name-to-sign field, and records
/// acceptance (`TERMS_AGREE_UPDATE-TERMSUPDATE`) before advancing to data sync.
/// Fails open — if the terms endpoint/session data is missing, it proceeds to
/// data sync rather than trapping the user.
class TosScreen extends ConsumerStatefulWidget {
  const TosScreen({super.key});

  @override
  ConsumerState<TosScreen> createState() => _TosScreenState();
}

class _TosScreenState extends ConsumerState<TosScreen> {
  _Phase _phase = _Phase.loading;
  String _terms = '';
  String _error = '';
  final _nameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _goSync() {
    if (mounted) context.go(Routes.dataSync);
  }

  Future<void> _load() async {
    final sm = ref.read(sessionManagerProvider);
    final url = sm.getServiceUrl('TERMS_MESSAGE-TERMS');
    final token = sm.getAuthToken();
    final storeId = sm.getStoreId();
    final userId = sm.getUserId();

    // Missing config → don't block the flow.
    if (url == null || url.isEmpty || token == null || storeId == null ||
        userId == null) {
      _goSync();
      return;
    }

    final res = await ref.read(tosRepositoryProvider).getTosStatus(
          url: url,
          authToken: token,
          userId: userId,
          versionId: await versionId(),
          deviceId: await deviceId(),
          storeId: storeId,
        );
    if (!mounted) return;
    if (!res.isSuccess) {
      setState(() {
        _phase = _Phase.error;
        _error = res.error?.toString() ?? 'Failed to load terms of service';
      });
      return;
    }
    final terms = res.value;
    if (terms == null || terms.isEmpty) {
      // No pending terms → already accepted.
      _goSync();
      return;
    }
    setState(() {
      _phase = _Phase.requires;
      _terms = terms;
    });
  }

  Future<void> _accept() async {
    final sm = ref.read(sessionManagerProvider);
    final url = sm.getServiceUrl('TERMS_AGREE_UPDATE-TERMSUPDATE');
    final token = sm.getAuthToken();
    final storeId = sm.getStoreId();
    final userId = sm.getUserId();
    if (url == null || token == null || storeId == null || userId == null) {
      _goSync();
      return;
    }
    setState(() => _phase = _Phase.accepting);
    final res = await ref.read(tosRepositoryProvider).acceptTos(
          url: url,
          authToken: token,
          userId: userId,
          storeId: storeId,
          deviceId: await deviceId(),
          signedUserName: _nameCtrl.text.trim(),
        );
    if (!mounted) return;
    if (res.isSuccess && res.value == true) {
      _goSync();
    } else {
      setState(() {
        _phase = _Phase.error;
        _error = res.error?.toString() ?? 'Failed to accept terms of service';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const Padding(
          padding: EdgeInsets.only(left: 8),
          child: Center(child: BrandLogo(size: 40)),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: Center(child: BrandLogo(size: 40)),
          ),
        ],
        title: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(AppConstants.appTitle,
                style: TextStyle(color: Colors.white, fontSize: 13)),
            Text('TERMS OF SERVICE',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: _body(),
      bottomNavigationBar: _phase == _Phase.requires
          ? Container(
              color: primary,
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nameCtrl.text.trim().isEmpty ? null : _accept,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white, foregroundColor: primary),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('ACCEPT'),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _body() {
    switch (_phase) {
      case _Phase.loading:
        return const Center(child: CircularProgressIndicator());
      case _Phase.accepting:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('accepting terms... please wait...'),
            ],
          ),
        );
      case _Phase.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                        onPressed: () {
                          setState(() => _phase = _Phase.loading);
                          _load();
                        },
                        child: const Text('RETRY')),
                    const SizedBox(width: 12),
                    TextButton(
                        onPressed: _goSync, child: const Text('CONTINUE')),
                  ],
                ),
              ],
            ),
          ),
        );
      case _Phase.requires:
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(child: Text(_terms)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: TextField(
                  controller: _nameCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Enter your name to continue',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }
}
