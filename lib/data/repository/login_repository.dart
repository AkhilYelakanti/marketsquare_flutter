import 'dart:convert';

import '../../core/constants.dart';
import '../../core/network/api_client.dart';
import '../models/device_setup_request.dart';
import '../models/device_setup_response.dart';
import '../models/token_response.dart';

/// Result wrapper mirroring Kotlin's `Result<T>` usage in LoginRepository.
class RepoResult<T> {
  final T? value;
  final Object? error;
  const RepoResult.success(this.value) : error = null;
  const RepoResult.failure(this.error) : value = null;
  bool get isSuccess => error == null;
}

/// Port of Kotlin `LoginRepository` (device setup + OAuth token).
class LoginRepository {
  final ApiClient _api;
  LoginRepository(this._api);

  /// POST https://{hostId}.cswg.com/devicesetup/1.0
  Future<RepoResult<DeviceSetupResponse>> login(
      String hostId, DeviceSetupRequest request) async {
    try {
      final url = AppConstants.deviceSetupUrl(hostId);
      final res = await _api.postJson(url, request.toJson());
      final rawBody = (res.data ?? '').toString();
      final ok = res.statusCode != null &&
          res.statusCode! >= 200 &&
          res.statusCode! < 300;
      if (!ok || rawBody.trim().isEmpty) {
        return RepoResult.failure(StateError(
            'Device setup failed (HTTP ${res.statusCode}). Please try again.'));
      }
      final json = jsonDecode(rawBody) as Map<String, dynamic>;
      return RepoResult.success(DeviceSetupResponse.fromJson(json));
    } catch (e) {
      return RepoResult.failure(e);
    }
  }

  /// OAuth client_credentials token request.
  /// Authorization: Basic {serviceId}; custom deviceId/accessId/versionId headers.
  Future<RepoResult<TokenResponse>> getAuthToken({
    required String tokenUrl,
    required String serviceId,
    required String deviceId,
    required String accessId,
    required String versionId,
  }) async {
    try {
      final res = await _api.postForm(
        tokenUrl,
        {
          'grant_type': AppConstants.grantType,
          'scope': AppConstants.tokenScope,
        },
        headers: {
          'Authorization': 'Basic $serviceId',
          'deviceId': deviceId,
          'accessId': accessId,
          'versionId': versionId,
        },
      );
      final rawBody = (res.data ?? '').toString();
      final json = jsonDecode(rawBody) as Map<String, dynamic>;
      return RepoResult.success(TokenResponse.fromJson(json));
    } catch (e) {
      return RepoResult.failure(e);
    }
  }
}
