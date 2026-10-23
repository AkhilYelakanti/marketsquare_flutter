import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Flutter equivalent of the native `SessionManager` (SharedPreferences-backed).
///
/// Only the slice-critical surface is implemented here; the native class also
/// parses a large "LOV1" config JSON that drives order/dashboard behaviour.
/// That config is stored verbatim under [_keyLov1Json] and can be parsed by
/// future feature modules as they are ported.
class SessionManager {
  static const _keyAuthToken = 'AUTH_TOKEN';
  static const _keyUserId = 'USER_ID';
  static const _keyStoreId = 'STORE_ID';
  static const _keyBuId = 'BU_ID';
  static const _keyHostId = 'HOST_ID';
  static const _keyServiceId = 'SERVICE_ID';
  static const _keyAccessPin = 'ACCESS_PIN';
  static const _keyBrandLogoUrl = 'BRAND_LOGO_URL';
  static const _keyBrandBgColor = 'BRAND_BACKGROUND_COLOR';
  static const _keyServiceUrlPrefix = 'SERVICE_URL_';
  static const _keyServiceUrlKeys = 'SERVICE_URL_KEYS';
  static const _keyRepStoreId = 'REP_SELECTED_STORE_ID';
  static const _keyRepStoreName = 'REP_SELECTED_STORE_NAME';
  static const _keyLov1Json = 'LOV1_CONFIG_JSON';

  final SharedPreferences _prefs;

  SessionManager(this._prefs);

  static Future<SessionManager> create() async =>
      SessionManager(await SharedPreferences.getInstance());

  // ── Service URL map ────────────────────────────────────────────────────────
  Future<void> saveServiceUrls(Map<String, String> map) async {
    await _prefs.setStringList(_keyServiceUrlKeys, map.keys.toList());
    for (final e in map.entries) {
      await _prefs.setString('$_keyServiceUrlPrefix${e.key}', e.value);
    }
  }

  String? getServiceUrl(String key) =>
      _prefs.getString('$_keyServiceUrlPrefix$key');

  Set<String> getAllServiceUrlKeys() =>
      (_prefs.getStringList(_keyServiceUrlKeys) ?? const []).toSet();

  // ── Auth / session ──────────────────────────────────────────────────────────
  Future<void> saveAuthToken(String token) =>
      _prefs.setString(_keyAuthToken, token);
  String? getAuthToken() => _prefs.getString(_keyAuthToken);

  Future<void> saveServiceId(String id) => _prefs.setString(_keyServiceId, id);
  String? getServiceId() => _prefs.getString(_keyServiceId);

  Future<void> saveSessionData(
      String storeId, String userId, String buId, String hostId) async {
    await _prefs.setString(_keyStoreId, storeId);
    await _prefs.setString(_keyUserId, userId);
    await _prefs.setString(_keyBuId, buId);
    await _prefs.setString(_keyHostId, hostId);
  }

  Future<void> saveAccessPin(String pin) =>
      _prefs.setString(_keyAccessPin, pin);
  String? getAccessPin() => _prefs.getString(_keyAccessPin);

  String? getStoreId() => _prefs.getString(_keyStoreId);
  String? getUserId() => _prefs.getString(_keyUserId);
  String? getBuId() => _prefs.getString(_keyBuId);
  String? getHostId() => _prefs.getString(_keyHostId);

  // ── Branding ─────────────────────────────────────────────────────────────────
  Future<void> saveBrandingData({String? logoUrl, String? backgroundColor}) async {
    if (logoUrl != null) await _prefs.setString(_keyBrandLogoUrl, logoUrl);
    if (backgroundColor != null) {
      await _prefs.setString(_keyBrandBgColor, backgroundColor);
    }
  }

  String? getBrandLogoUrl() => _prefs.getString(_keyBrandLogoUrl);
  String? getBrandBackgroundColor() => _prefs.getString(_keyBrandBgColor);

  // ── Rep accounts ──────────────────────────────────────────────────────────────
  /// A "rep" account's userId starts with a letter (native parity).
  bool isRepAccount() {
    final u = getUserId();
    if (u == null || u.isEmpty) return false;
    final first = u[0];
    return RegExp(r'[A-Za-z]').hasMatch(first);
  }

  Future<void> saveRepSelectedCustomer(String storeId, String storeName) async {
    await _prefs.setString(_keyRepStoreId, storeId);
    await _prefs.setString(_keyRepStoreName, storeName);
  }

  String? getRepSelectedStoreId() => _prefs.getString(_keyRepStoreId);
  String? getRepSelectedStoreName() => _prefs.getString(_keyRepStoreName);

  Future<void> clearRepSelectedCustomer() async {
    await _prefs.remove(_keyRepStoreId);
    await _prefs.remove(_keyRepStoreName);
  }

  /// Active store = rep-selected store if present, else the session store.
  String getActiveStoreId() =>
      getRepSelectedStoreId() ?? getStoreId() ?? '';

  /// Parsed LOV1 config root (null when not set / unparseable).
  Map<String, dynamic>? lov1Root() {
    final raw = getLov1ConfigJson();
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final v = jsonDecode(raw);
      return v is Map<String, dynamic> ? v : null;
    } catch (_) {
      return null;
    }
  }

  /// Resolves the submit endpoint for an order request type. Native parity:
  /// LOV1 `urlsMap` (exact → case/underscore-normalized) first, then the stored
  /// service-URL map with common variants.
  String? getOrderServiceUrl(String requestType) {
    final root = lov1Root();
    final urls = root?['urlsMap'];
    if (urls is Map) {
      final direct = urls[requestType];
      if (direct is String && direct.isNotEmpty) return direct;
      final norm = requestType.toUpperCase().replaceAll(' ', '_');
      for (final e in urls.entries) {
        if (e.key.toString().toUpperCase().replaceAll(' ', '_') == norm) {
          final v = e.value;
          if (v is String && v.isNotEmpty) return v;
        }
      }
    }
    final candidates = [
      requestType,
      requestType.toUpperCase(),
      '${requestType.toUpperCase()}-ORDER1',
      '${requestType.toUpperCase()}-ORDER',
      'SUBMIT_$requestType',
      'SUBMIT_ORDER',
      'ORDER_SUBMIT',
    ];
    for (final c in candidates) {
      final url = getServiceUrl(c);
      if (url != null && url.isNotEmpty) return url;
    }
    return null;
  }

  // ── LOV1 string/list config ───────────────────────────────────────────────────
  String _lov1String(String key) {
    final v = lov1Root()?[key];
    return v is String ? v.trim() : '';
  }

  List<String> _lov1List(String key) {
    final v = lov1Root()?[key];
    if (v is List) {
      return v.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
    }
    return [];
  }

  List<String> getMessagesSubjects() => _lov1List('messagesSubject');
  List<String> getStoreInvoices() => _lov1List('storeInvoices');

  // ── Rep customer list (Change Store) ──────────────────────────────────────────
  /// Customers a rep can switch between — LOV1 `storeNumbers` (or `customerList`).
  /// Entries are either `"ID-Name"` / `"ID"` strings or `{storeId, storeName}`
  /// objects. Falls back to the session store when the config is absent.
  List<CustomerEntry> getStoreNumbers() {
    final root = lov1Root();
    final arr = root?['storeNumbers'] ?? root?['customerList'];
    final out = <CustomerEntry>[];
    if (arr is List) {
      for (final el in arr) {
        if (el is String) {
          final raw = el.trim();
          if (raw.isEmpty) continue;
          out.add(raw.contains('-')
              ? CustomerEntry(
                  raw.substring(0, raw.indexOf('-')).trim(),
                  raw.substring(raw.indexOf('-') + 1).trim())
              : CustomerEntry(raw, ''));
        } else if (el is Map) {
          final id = (el['storeId'] ?? '').toString().trim();
          final name = (el['storeName'] ?? '').toString().trim();
          if (id.isEmpty) continue;
          if (name.isEmpty && id.contains('-')) {
            out.add(CustomerEntry(id.substring(0, id.indexOf('-')).trim(),
                id.substring(id.indexOf('-') + 1).trim()));
          } else {
            out.add(CustomerEntry(id, name));
          }
        }
      }
    }
    if (out.isNotEmpty) return out;
    final storeId = getStoreId();
    if (storeId == null) return const [];
    final storeName = _lov1String('storeName');
    return [CustomerEntry(storeId, storeName.isEmpty ? storeId : storeName)];
  }

  // ── Item refresh metadata (Data Sync) ────────────────────────────────────────
  Future<void> saveRefreshData(String fileName, String date, String recordCount) async {
    await _prefs.setString('REFRESH_FILENAME', fileName);
    await _prefs.setString('REFRESH_DATE', date);
    await _prefs.setString('REFRESH_RECORD_COUNT', recordCount);
    await _prefs.setInt('ITEM_REFRESH_EPOCH', DateTime.now().millisecondsSinceEpoch);
  }

  String? getRefreshFileName() => _prefs.getString('REFRESH_FILENAME');
  String? getRefreshDate() => _prefs.getString('REFRESH_DATE');
  String? getRefreshRecordCount() => _prefs.getString('REFRESH_RECORD_COUNT');
  int getItemRefreshEpoch() => _prefs.getInt('ITEM_REFRESH_EPOCH') ?? 0;

  // ── Saved item codes (Manage Saved Items) ─────────────────────────────────────
  Set<String> getSavedItemCodes() =>
      (_prefs.getStringList('SAVED_ITEM_CODES') ?? const []).toSet();
  Future<void> saveSavedItemCodes(Set<String> codes) =>
      _prefs.setStringList('SAVED_ITEM_CODES', codes.toList());

  // ── Help / support (LOV1-driven; defaults empty) ──────────────────────────────
  String getSupportEmail() {
    final e = _lov1String('email');
    return e.isNotEmpty ? e : (_prefs.getString('SUPPORT_EMAIL') ?? '');
  }

  String getSupportPhone() {
    final p = _lov1String('phoneNumber');
    return p.isNotEmpty ? p : (_prefs.getString('SUPPORT_PHONE') ?? '');
  }
  Future<void> saveOperationalManual(String content) =>
      _prefs.setString('OPERATIONAL_MANUAL', content);
  String? getOperationalManual() => _prefs.getString('OPERATIONAL_MANUAL');
  Future<void> saveDebugLoggingEnabled(bool v) =>
      _prefs.setBool('DEBUG_LOGGING_ENABLED', v);
  bool isDebugLoggingEnabled() => _prefs.getBool('DEBUG_LOGGING_ENABLED') ?? true;

  // ── LOV1 config blob (parsed lazily by feature modules) ──────────────────────
  Future<void> saveLov1ConfigJson(String raw) =>
      _prefs.setString(_keyLov1Json, raw);
  String? getLov1ConfigJson() => _prefs.getString(_keyLov1Json);

  // ── Clearing ──────────────────────────────────────────────────────────────────
  /// Clears prefs for a fresh login. The FCM token is device-scoped and
  /// survives (native parity: it lived in a separate prefs file).
  Future<void> clearSession() async {
    final keys = _prefs.getKeys().toList();
    for (final k in keys) {
      if (k.startsWith(fcmTokenKey)) continue;
      await _prefs.remove(k);
    }
  }

  // ── FCM token (device-scoped; survives clearSession) ──────────────────────────
  static const fcmTokenKey = 'FCM_TOKEN';
  Future<void> saveFcmToken(String token) =>
      _prefs.setString(fcmTokenKey, token);
  String? getCachedFcmToken() => _prefs.getString(fcmTokenKey);
}

/// A rep-selectable customer/store (native `CustomerEntry`).
class CustomerEntry {
  final String storeId;
  final String storeName;
  const CustomerEntry(this.storeId, this.storeName);
}
