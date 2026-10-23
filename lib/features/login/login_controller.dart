import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/constants.dart';
import '../../core/device_meta.dart';
import '../../data/models/device_setup_request.dart';
import '../../data/push/fcm_service.dart';
import '../../data/session/session_providers.dart';

/// Immutable UI state for the login/setup screen.
class LoginState {
  final String userId;
  final String password;
  final String hostId;
  final bool isLoading;
  final String? error;
  final bool loginSuccess;
  final bool showConfirmationDialog;

  const LoginState({
    this.userId = '',
    this.password = '',
    this.hostId = '',
    this.isLoading = false,
    this.error,
    this.loginSuccess = false,
    this.showConfirmationDialog = false,
  });

  LoginState copyWith({
    String? userId,
    String? password,
    String? hostId,
    bool? isLoading,
    Object? error = _sentinel,
    bool? loginSuccess,
    bool? showConfirmationDialog,
  }) {
    return LoginState(
      userId: userId ?? this.userId,
      password: password ?? this.password,
      hostId: hostId ?? this.hostId,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _sentinel) ? this.error : error as String?,
      loginSuccess: loginSuccess ?? this.loginSuccess,
      showConfirmationDialog:
          showConfirmationDialog ?? this.showConfirmationDialog,
    );
  }

  static const _sentinel = Object();
}

/// Port of native `LoginViewModel`. Drives device setup + OAuth token.
class LoginController extends AutoDisposeNotifier<LoginState> {
  @override
  LoginState build() => const LoginState();

  void setUserId(String v) => state = state.copyWith(userId: v);
  void setPassword(String v) => state = state.copyWith(password: v);
  void setHostId(String v) => state = state.copyWith(hostId: v);
  void clearError() => state = state.copyWith(error: null);
  void dismissConfirmation() =>
      state = state.copyWith(showConfirmationDialog: false);

  /// Prefills from the stored session (user-setup / re-login flow).
  void onUserSetup() {
    final sm = ref.read(sessionManagerProvider);
    state = state.copyWith(
      userId: sm.getUserId() ?? '',
      hostId: sm.getHostId() ?? '',
      password: sm.getAccessPin() ?? '',
    );
  }

  void onLoginClick({required bool isUserSetup}) {
    if (isUserSetup) {
      state = state.copyWith(showConfirmationDialog: true);
    } else {
      _login();
    }
  }

  Future<void> confirmAndLogin() async {
    state = state.copyWith(showConfirmationDialog: false);
    // Re-login: wipe prefs. (Native also drops DB caches for a different user;
    // that is a follow-up once the DB layer is ported.)
    await ref.read(sessionManagerProvider).clearSession();
    await _login();
  }

  Future<void> _login() async {
    final s = state;
    if (s.userId.isEmpty || s.password.isEmpty || s.hostId.isEmpty) {
      state = s.copyWith(error: 'All fields are required');
      return;
    }

    state = s.copyWith(isLoading: true, error: null);
    final sm = ref.read(sessionManagerProvider);
    final repo = ref.read(loginRepositoryProvider);

    final deviceId = await _deviceId();
    final info = await PackageInfo.fromPlatform();
    final fcmToken = (await FcmService.getToken()) ?? '';
    final meta = await _deviceMeta();

    final request = DeviceSetupRequest(
      deviceId: deviceId,
      accessId: s.userId,
      accessPin: s.password,
      versionId: info.version,
      appOS: Platform.isIOS ? 'iOS' : 'Android',
      appOSVersion: meta.osVersion,
      fcmToken: fcmToken,
      manufacturer: meta.manufacturer,
      model: meta.model,
      brand: meta.brand,
    );

    final result = await repo.login(s.hostId, request);
    if (!result.isSuccess) {
      state = state.copyWith(
          isLoading: false,
          error: _msg(result.error, 'Login request failed'));
      return;
    }

    final response = result.value!;
    if (response.status != 'SUCCESS') {
      state = state.copyWith(
        isLoading: false,
        error: response.errorMessage ??
            'Login failed. Please check your credentials.',
      );
      return;
    }

    if (response.serviceUrlMap != null) {
      await sm.saveServiceUrls(response.serviceUrlMap!);
    }
    await sm.saveBrandingData(
      logoUrl: response.brandLogoUrl,
      backgroundColor: response.brandBackgroundColor,
    );
    ref.read(brandColorProvider.notifier).setFromHex(response.brandBackgroundColor);

    if (response.storeId != null && response.buId != null) {
      await sm.saveSessionData(
          response.storeId!, s.userId, response.buId!, s.hostId);
    }
    if (response.serviceId != null) {
      await sm.saveServiceId(response.serviceId!);
    }
    await sm.saveAccessPin(s.password);

    final tokenUrl = response.serviceUrlMap?[AppConstants.serviceKeyAccessToken];
    if (tokenUrl == null || response.serviceId == null) {
      state = state.copyWith(
        isLoading: false,
        error: response.errorMessage ?? 'Incomplete login response from server.',
      );
      return;
    }

    final tokenResult = await repo.getAuthToken(
      tokenUrl: tokenUrl,
      serviceId: response.serviceId!,
      deviceId: deviceId,
      accessId: s.userId,
      versionId: info.version,
    );
    if (!tokenResult.isSuccess) {
      state = state.copyWith(
          isLoading: false,
          error: _msg(tokenResult.error, 'Token retrieval failed'));
      return;
    }

    await sm.saveAuthToken(tokenResult.value!.accessToken);
    state = state.copyWith(isLoading: false, loginSuccess: true);
  }

  // Device-setup identity. Delegates to the shared [deviceId] (Android
  // ANDROID_ID via platform channel), so setup registers the same id the
  // native app used instead of device_info_plus's Build.ID.
  Future<String> _deviceId() => deviceId();

  Future<_DeviceMeta> _deviceMeta() async {
    final plugin = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final a = await plugin.androidInfo;
      return _DeviceMeta(a.manufacturer, a.model, a.brand, a.version.release);
    } else if (Platform.isIOS) {
      final i = await plugin.iosInfo;
      return _DeviceMeta('Apple', i.model, 'Apple', i.systemVersion);
    }
    return const _DeviceMeta('', '', '', '');
  }

  String _msg(Object? e, String fallback) {
    if (e is StateError) return e.message;
    return e?.toString() ?? fallback;
  }
}

class _DeviceMeta {
  final String manufacturer;
  final String model;
  final String brand;
  final String osVersion;
  const _DeviceMeta(this.manufacturer, this.model, this.brand, this.osVersion);
}

final loginControllerProvider =
    AutoDisposeNotifierProvider<LoginController, LoginState>(
        LoginController.new);
