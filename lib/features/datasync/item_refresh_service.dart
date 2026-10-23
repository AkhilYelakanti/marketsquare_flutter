import 'package:flutter/foundation.dart' show debugPrint;
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

      // LOV1 order/dashboard configuration (ORDER_DEPT_TYPES-LOV1). This drives
      // the customer list, order-entry control buttons, dynamic item tiles and
      // form fields — without it OrderConfig falls back to empty defaults.
      // Native parity: ItemRefreshService saves the raw body via saveLov1ConfigJson.
      final lov1Url = session.getServiceUrl('ORDER_DEPT_TYPES-LOV1');
      if (lov1Url != null && lov1Url.isNotEmpty) {
        onProgress('Loading order configuration...');
        final lov1 = await repo.postText(lov1Url, token, {
          'deviceId': dev,
          'storeId': storeId,
          'userName': userId,
          'versionId': ver,
        });
        if (lov1.isSuccess && (lov1.value ?? '').trim().isNotEmpty) {
          await session.saveLov1ConfigJson(lov1.value!);
        }
      }

      final itemUserName = session.isRepAccount() ? userId : storeId;
      final request = {
        'deviceId': dev,
        'storeId': storeId,
        'userName': itemUserName,
        'versionId': ver,
      };

      // Item file (full replace of the item table).
      final url = session.getServiceUrl('ITEMS_REFRESH-ITEM1');
      if (url == null || url.isEmpty) {
        onProgress('Item data endpoint not configured — skipped.');
      } else {
        onProgress('Retrieving Item Data...');
        final res = await repo.getItemsRefresh(url, token, request);
        if (res.isSuccess) {
          onProgress('Refreshing Item Data...');
          final count = await itemDb.ingestBytes(res.value!.bytes);
          final name = res.value!.fileName.isNotEmpty
              ? res.value!.fileName
              : 'item_refresh_$storeId';
          await session.saveRefreshData(name, _now(), '$count');
        }
      }

      // Full inventory file (ITEMS_INVENTORY-ITEM2) — merged onto the item table
      // by (ITEM_ID, DEPT_NAME); native parity.
      final invUrl = session.getServiceUrl('ITEMS_INVENTORY-ITEM2');
      if (invUrl != null && invUrl.isNotEmpty) {
        onProgress('Retrieving Inventory Data...');
        final invRes = await repo.getItemsRefresh(invUrl, token, request);
        if (invRes.isSuccess) {
          onProgress('Refreshing Inventory Data...');
          await itemDb.ingestInventoryMergeBytes(invRes.value!.bytes);
        }
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Fetches + saves the LOV1 order/dashboard config on demand (native re-fetches
  /// it on order-entry enter). Returns true when a non-empty config was saved.
  Future<bool> refreshLov1([void Function(String)? onProgress]) async {
    try {
      final storeId = session.getActiveStoreId();
      final userId = session.getUserId();
      if (storeId.isEmpty || userId == null) return false;
      final lov1Url = session.getServiceUrl('ORDER_DEPT_TYPES-LOV1');
      if (lov1Url == null || lov1Url.isEmpty) return false;

      final serviceId = session.getServiceId();
      final dev = await deviceId();
      final ver = await versionId();

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

      onProgress?.call('Loading order configuration...');
      final lov1 = await repo.postText(lov1Url, token, {
        'deviceId': dev,
        'storeId': storeId,
        'userName': userId,
        'versionId': ver,
      });
      if (lov1.isSuccess && (lov1.value ?? '').trim().isNotEmpty) {
        await session.saveLov1ConfigJson(lov1.value!);
        debugPrint('LOV1: saved ${lov1.value!.length} chars');
        return true;
      }
      debugPrint(
          'LOV1 fetch failed: success=${lov1.isSuccess} err=${lov1.error} '
          'len=${(lov1.value ?? '').length} url=$lov1Url');
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Delta inventory refresh (ITEMS_INVENTORY-DELTA): fetches only inventory
  /// changes since the last sync and merges them onto the item table. Called on
  /// order-entry enter. No-op (returns true) when the endpoint isn't configured.
  /// Port of `ItemRefreshService.runDeltaInventoryRefresh`.
  Future<bool> runDeltaInventoryRefresh(void Function(String) onProgress) async {
    try {
      final storeId = session.getActiveStoreId();
      final userId = session.getUserId();
      if (storeId.isEmpty || userId == null) return true;

      final deltaUrl = session.getServiceUrl('ITEMS_INVENTORY-DELTA');
      if (deltaUrl == null || deltaUrl.isEmpty) return true;

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

      onProgress('Refreshing Inventory Data...');
      final itemUserName = session.isRepAccount() ? userId : storeId;
      final res = await repo.postText(deltaUrl, token, {
        'deviceId': dev,
        'storeId': storeId,
        'userName': itemUserName,
        'versionId': ver,
      });
      if (!res.isSuccess) return false;
      await itemDb.ingestInventoryMerge(res.value!);
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
