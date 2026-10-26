import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/device_meta.dart';
import '../repository/data_sync_repository.dart';
import '../repository/login_repository.dart';
import '../session/session_manager.dart';
import '../session/session_providers.dart';
import 'image_store.dart';

/// Result of an image-download run.
class ImageDownloadResult {
  final bool ok;
  final int count;
  final String message;
  const ImageDownloadResult(this.ok, this.count, this.message);
}

/// Port of native `ImageDownloadService`: the full image pipeline —
/// auth token → IMAGE_DELETE_LIST cleanup → per-package IMAGES_DOWNLOAD +
/// zip extraction → DEVICE_IMAGE_INFO_UPDATE confirmation → persist stats.
/// Individual package failures are logged but don't fail the whole run.
class ImageDownloadService {
  final SessionManager session;
  final DataSyncRepository repo;
  final LoginRepository login;

  ImageDownloadService({
    required this.session,
    required this.repo,
    required this.login,
  });

  bool isImagesEnabled() => session.isImagesEnabled();

  /// True when enough days have passed since the last download (native
  /// `imagesTimeToRefresh`; 0 = always refresh).
  bool isRefreshDue() {
    final days = session.getImagesTimeToRefresh();
    if (days <= 0) return true;
    final last = session.getImageDownloadEpoch();
    if (last == 0) return true;
    final elapsed = DateTime.now().millisecondsSinceEpoch - last;
    return elapsed >= days * 24 * 60 * 60 * 1000;
  }

  Future<ImageDownloadResult> executeDownload(
      void Function(String) onProgress) async {
    final temps = <File>[];
    try {
      await ImageStore.init();
      final dir = ImageStore.dir!;
      final storeId = session.getActiveStoreId();
      final userId = session.getUserId();
      if (storeId.isEmpty || userId == null) {
        return const ImageDownloadResult(false, 0, 'Not logged in.');
      }
      final dev = await deviceId();
      final ver = await versionId();

      // Auth token — silent background step (never surfaced in the popup).
      final tokenUrl = session.getServiceUrl('ACCESS_TOKEN');
      final serviceId = session.getServiceId();
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
      if (token == null || token.isEmpty) {
        return const ImageDownloadResult(false, 0, 'Could not start download.');
      }

      // ── 1) Refresh the LOV first so packages/config are current ─────────────
      onProgress('Refreshing configuration...');
      final lovUrl = session.getServiceUrl('ORDER_DEPT_TYPES-LOV1');
      if (lovUrl != null && lovUrl.isNotEmpty) {
        final res = await repo.postText(lovUrl, token, {
          'deviceId': dev,
          'storeId': storeId,
          'userName': userId,
          'versionId': ver,
        });
        if (res.isSuccess && (res.value ?? '').trim().isNotEmpty) {
          await session.saveLov1ConfigJson(res.value!);
        }
      }

      // Re-check enablement against the freshly loaded config.
      if (!session.isImagesEnabled()) {
        return const ImageDownloadResult(false, 0, 'Images are not enabled.');
      }

      final header = <String, dynamic>{
        'deviceId': dev,
        'storeId': storeId,
        'userName': storeId,
        'versionId': ver,
      };

      // ── 2) Delete-list cleanup ──────────────────────────────────────────────
      onProgress('Performing image cleanup...');
      final deleteUrl = session.getServiceUrl('IMAGE_DELETE_LIST');
      if (deleteUrl != null && deleteUrl.isNotEmpty) {
        final res = await repo.postText(deleteUrl, token, header);
        if (res.isSuccess) {
          try {
            final obj = jsonDecode(res.value!) as Map<String, dynamic>;
            final names = (obj['fileNamesToDelete'] as List?) ?? const [];
            for (final n in names) {
              final f = File('${dir.path}/$n');
              if (f.existsSync()) f.deleteSync();
            }
          } catch (_) {/* ignore parse errors */}
        }
      }

      // ── 3) Download ALL packages first (to temp files) ──────────────────────
      final packages = session.getDeviceDownloadPackages();
      final total = packages.length;
      final downloadUrl = session.getServiceUrl('IMAGES_DOWNLOAD');
      final downloaded = <DownloadPackage, File>{};
      if (downloadUrl != null && downloadUrl.isNotEmpty && total > 0) {
        var done = 0;
        for (final pkg in packages) {
          final res = await repo.downloadImagePackage(downloadUrl, token, {
            ...header,
            'pkgDetails': {'packageName': pkg.pkgName},
          });
          done++;
          onProgress('Downloaded $done of $total packages...');
          if (res.isSuccess) {
            final tmp = File('${dir.path}/.tmp_${done}_${pkg.pkgName}');
            tmp.writeAsBytesSync(res.value!);
            temps.add(tmp);
            downloaded[pkg] = tmp;
          }
        }
      }

      // ── 4) Extract ALL downloaded packages (overwriting duplicates) ─────────
      final succeeded = <DownloadPackage>[];
      var ex = 0;
      for (final entry in downloaded.entries) {
        ex++;
        onProgress('Extracting $ex of ${downloaded.length}...');
        try {
          _extractZip(entry.value.readAsBytesSync(), dir);
          succeeded.add(entry.key);
        } catch (_) {/* skip bad package */}
      }

      // ── 5) Confirm receipt with the successfully extracted packages ─────────
      onProgress('Confirming image receipt...');
      final updateUrl = session.getServiceUrl('DEVICE_IMAGE_INFO_UPDATE');
      if (updateUrl != null && updateUrl.isNotEmpty && succeeded.isNotEmpty) {
        await repo.postText(updateUrl, token, {
          'deviceId': dev,
          'storeId': storeId,
          'downloadedPkgList': succeeded
              .map((p) => {'pkgName': p.pkgName, 'pkgLastUpdatedTs': p.pkgLastUpdatedTs})
              .toList(),
        });
      }

      final count = ImageStore.count();
      await session.saveImageDownloadData(_timestamp(), '$count');
      return ImageDownloadResult(true, count, 'Images downloaded: $count');
    } catch (e) {
      return ImageDownloadResult(false, 0, 'Image download failed: $e');
    } finally {
      for (final t in temps) {
        try {
          if (t.existsSync()) t.deleteSync();
        } catch (_) {}
      }
    }
  }

  /// Extracts each file to the image dir, replacing any existing file of the
  /// same name (writeAsBytesSync truncates/overwrites).
  void _extractZip(List<int> bytes, Directory target) {
    final archive = ZipDecoder().decodeBytes(bytes);
    for (final entry in archive) {
      if (entry.isFile) {
        final name = entry.name.split('/').last;
        if (name.isEmpty || name.startsWith('.tmp_')) continue;
        File('${target.path}/$name').writeAsBytesSync(entry.content as List<int>);
      }
    }
  }

  String _timestamp() {
    final d = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour < 12 ? 'AM' : 'PM';
    return '${two(d.month)}/${two(d.day)}/${d.year} ${two(h12)}:${two(d.minute)} $ampm';
  }
}

final imageDownloadServiceProvider = Provider<ImageDownloadService>((ref) {
  return ImageDownloadService(
    session: ref.read(sessionManagerProvider),
    repo: DataSyncRepository(),
    login: ref.read(loginRepositoryProvider),
  );
});
