import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/device_meta.dart';
import '../../data/db/item_file_db.dart';
import '../../data/repository/data_sync_repository.dart';
import '../../data/repository/login_repository.dart';
import '../../data/session/session_manager.dart';
import '../../data/session/session_providers.dart';

/// Port of `ItemRefreshService.runFullRefresh` (item-file path). Resolves the
/// ITEMS_REFRESH endpoint, authenticates, downloads the item file and ingests it
/// into the dynamic item table. Steps with no configured URL are skipped
/// (fail-soft), matching native.
///
/// [loadSampleCatalog] ingests a bundled sample item file so item search works
/// without a live backend (dev/demo aid; not part of the native app).
class ItemRefreshService {
  final SessionManager session;
  final DataSyncRepository repo;
  final LoginRepository login;
  final ItemFileDb itemDb;

  ItemRefreshService({
    required this.session,
    required this.repo,
    required this.login,
    required this.itemDb,
  });

  Future<bool> runFullRefresh(void Function(String) onProgress) async {
    try {
      final storeId = session.getActiveStoreId();
      final userId = session.getUserId();
      if (storeId.isEmpty || userId == null) return false;
      final serviceId = session.getServiceId();
      final dev = await deviceId();
      final ver = await versionId();

      onProgress('Authenticating...');
      final tokenUrl = session.getServiceUrl('ACCESS_TOKEN');
      String? token = session.getAuthToken();
      if (tokenUrl != null && serviceId != null) {
        final t = await login.getAuthToken(
          tokenUrl: tokenUrl,
          serviceId: serviceId,
          deviceId: dev,
          accessId: userId,
          versionId: ver,
        );
        if (t.isSuccess) {
          token = t.value!.accessToken;
          await session.saveAuthToken(token);
        }
      }
      if (token == null || token.isEmpty) return false;

      final itemUserName = session.isRepAccount() ? userId : storeId;
      final request = {
        'deviceId': dev,
        'storeId': storeId,
        'userName': itemUserName,
        'versionId': ver,
      };

      final url = session.getServiceUrl('ITEMS_REFRESH-ITEM1');
      if (url == null || url.isEmpty) {
        onProgress('Item data endpoint not configured — skipped.');
        return true; // fail-soft (native skips missing URLs)
      }

      onProgress('Retrieving Item Data...');
      final res = await repo.getItemsRefresh(url, token, request);
      if (!res.isSuccess) return true; // fail-soft, keep existing data

      onProgress('Refreshing Item Data...');
      final count = await itemDb.ingestBytes(res.value!.bytes);
      final name = res.value!.fileName.isNotEmpty
          ? res.value!.fileName
          : 'item_refresh_$storeId';
      await session.saveRefreshData(name, _now(), '$count');
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Dev/demo: ingest the bundled sample catalog so item search returns results.
  Future<int> loadSampleCatalog() async {
    final content = await rootBundle.loadString('assets/sample_items.psv');
    final count = await itemDb.ingestText(content);
    await session.saveRefreshData('sample_items.psv', _now(), '$count');
    return count;
  }

  String _now() {
    final d = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour < 12 ? 'AM' : 'PM';
    return '${two(d.month)}/${two(d.day)}/${d.year} ${two(h12)}:${two(d.minute)} $ampm';
  }
}

final itemRefreshServiceProvider = Provider<ItemRefreshService>((ref) {
  return ItemRefreshService(
    session: ref.read(sessionManagerProvider),
    repo: DataSyncRepository(),
    login: ref.read(loginRepositoryProvider),
    itemDb: ItemFileDb(),
  );
});
