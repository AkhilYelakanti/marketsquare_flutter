import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/network/api_log.dart';
import 'login_repository.dart' show RepoResult;

/// Download bundle: the raw item-file bytes + filename from Content-Disposition.
class ItemFileDownload {
  final String fileName;
  final List<int> bytes;
  const ItemFileDownload(this.fileName, this.bytes);
}

/// Port of the item-refresh parts of Kotlin `DataSyncRepository` (Dio).
class DataSyncRepository {
  final Dio _dio;
  DataSyncRepository({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(minutes: 5),
              sendTimeout: const Duration(minutes: 5),
              validateStatus: (_) => true,
            ));

  Options _headers(String token, ResponseType type) => Options(
        responseType: type,
        contentType: Headers.jsonContentType,
        headers: {
          'Authorization': 'Bearer $token',
          'CSOR-Token': token,
          // Binary downloads accept octet-stream; JSON/text endpoints (LOV1,
          // inventory delta) must NOT send that or the server may 406.
          'Accept': type == ResponseType.bytes
              ? 'application/octet-stream'
              : 'application/json',
        },
      );

  /// Binary item-file download (ITEMS_REFRESH-ITEM1). Returns bytes + filename.
  Future<RepoResult<ItemFileDownload>> getItemsRefresh(
      String url, String token, Map<String, dynamic> request) async {
    try {
      final res = await _dio.post(url,
          data: jsonEncode(request), options: _headers(token, ResponseType.bytes));
      final code = res.statusCode ?? 0;
      if (code < 200 || code >= 300) {
        return RepoResult.failure(StateError('HTTP $code for ITEMS_REFRESH'));
      }
      final cd = res.headers.value('content-disposition') ?? '';
      final fileName = RegExp(r'filename="?([^"]+)"?', caseSensitive: false)
              .firstMatch(cd)
              ?.group(1)
              ?.trim() ??
          '';
      final data = res.data;
      final bytes = data is List<int> ? data : <int>[];
      return RepoResult.success(ItemFileDownload(fileName, bytes));
    } catch (e) {
      return RepoResult.failure(e);
    }
  }

  /// Operational-manual PDF download (OPERATIONAL_MANUAL-MANUAL). Binary like
  /// [getItemsRefresh]; the file payload itself is not logged to [ApiLog].
  Future<RepoResult<List<int>>> getOperationalManualPdf(
      String url, String token, Map<String, dynamic> request) async {
    try {
      final res = await _dio.post(url,
          data: jsonEncode(request), options: _headers(token, ResponseType.bytes));
      final code = res.statusCode ?? 0;
      ApiLog.add(url, jsonEncode(request), 'HTTP $code (binary PDF, not shown)');
      if (code < 200 || code >= 300) {
        return RepoResult.failure(StateError('HTTP $code for OPERATIONAL_MANUAL'));
      }
      final data = res.data;
      final bytes = data is List<int> ? data : <int>[];
      if (bytes.isEmpty) return RepoResult.failure(StateError('Empty PDF'));
      return RepoResult.success(bytes);
    } catch (e) {
      return RepoResult.failure(e);
    }
  }

  /// Binary image-package download (IMAGES_DOWNLOAD). Returns the raw zip bytes.
  Future<RepoResult<List<int>>> downloadImagePackage(
      String url, String token, Map<String, dynamic> request) async {
    try {
      final res = await _dio.post(url,
          data: jsonEncode(request), options: _headers(token, ResponseType.bytes));
      final code = res.statusCode ?? 0;
      ApiLog.add(url, jsonEncode(request), 'HTTP $code (binary zip, not shown)');
      if (code < 200 || code >= 300) {
        return RepoResult.failure(StateError('HTTP $code for IMAGES_DOWNLOAD'));
      }
      final data = res.data;
      final bytes = data is List<int> ? data : <int>[];
      if (bytes.isEmpty) return RepoResult.failure(StateError('Empty package'));
      return RepoResult.success(bytes);
    } catch (e) {
      return RepoResult.failure(e);
    }
  }

  /// Text endpoints (LOV1 config, inventory).
  Future<RepoResult<String>> postText(
      String url, String token, Map<String, dynamic> request) async {
    try {
      final res = await _dio.post(url,
          data: jsonEncode(request), options: _headers(token, ResponseType.plain));
      final code = res.statusCode ?? 0;
      final body = (res.data ?? '').toString();
      ApiLog.add(url, jsonEncode(request), body);
      if (code >= 200 && code < 300) return RepoResult.success(body);
      return RepoResult.failure(StateError('HTTP $code'));
    } catch (e) {
      return RepoResult.failure(e);
    }
  }
}
