import 'dart:convert';

import '../../core/network/api_client.dart';
import '../../data/repository/login_repository.dart' show RepoResult;

/// Port of native `TOSRepository` — fetch the terms-of-service status and
/// record acceptance. Both calls send `Authorization: Bearer <token>` plus the
/// `CSOR-Token` header, mirroring the native Ktor client.
class TosRepository {
  final ApiClient _api;
  TosRepository(this._api);

  Map<String, String> _headers(String authToken) => {
        'Authorization': 'Bearer $authToken',
        'CSOR-Token': authToken,
      };

  /// GET-status (POST body). Returns the pending terms text when a NEW terms
  /// version requires acceptance, or null when nothing is pending (already
  /// accepted / no terms configured).
  Future<RepoResult<String?>> getTosStatus({
    required String url,
    required String authToken,
    required String userId,
    required String versionId,
    required String deviceId,
    required String storeId,
  }) async {
    try {
      final body = {
        'header': {
          'channel': 'mobi',
          'userName': userId,
          'versionId': versionId,
          'deviceId': deviceId,
        },
        'data': {
          'storeId': storeId,
          'deviceId': deviceId,
        },
      };
      final res = await _api.postJson(url, body, headers: _headers(authToken));
      final raw = (res.data ?? '').toString();
      if (raw.trim().isEmpty) {
        return RepoResult.failure(StateError('Empty TOS response'));
      }
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if (json['status'] != 'SUCCESS') {
        return RepoResult.failure(
            StateError('Invalid TOS response from server'));
      }
      final data = json['data'];
      if (data is List) {
        for (final item in data) {
          if (item is Map &&
              item['termsAndConditionsStatus'] == 'NEW' &&
              (item['termsAndConditionsMgs'] ?? '').toString().isNotEmpty) {
            return RepoResult.success(
                item['termsAndConditionsMgs'].toString());
          }
        }
      }
      // No NEW terms → nothing to accept.
      return const RepoResult.success(null);
    } catch (e) {
      return RepoResult.failure(e);
    }
  }

  /// Records acceptance. Returns true on SUCCESS.
  Future<RepoResult<bool>> acceptTos({
    required String url,
    required String authToken,
    required String userId,
    required String storeId,
    required String deviceId,
    required String signedUserName,
  }) async {
    try {
      final body = {
        'header': {
          'channel': 'Mobile',
          'userName': userId,
        },
        'data': {
          'storeId': storeId,
          'deviceId': deviceId,
          'termsAndConditionsStatus': 'ACCEPTED',
          'signedUserName': signedUserName,
        },
      };
      final res = await _api.postJson(url, body, headers: _headers(authToken));
      final raw = (res.data ?? '').toString();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return RepoResult.success(json['status'] == 'SUCCESS');
    } catch (e) {
      return RepoResult.failure(e);
    }
  }
}
