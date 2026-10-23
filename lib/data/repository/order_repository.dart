import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../db/pending_order.dart';
import '../models/order_models.dart';
import '../session/session_manager.dart';
import 'login_repository.dart' show RepoResult;

/// Port of the order-submit path of Kotlin `OrderRepository`.
/// Builds the Section 16.3.2 payload (byte-faithful to the native builder) and
/// posts with `Authorization: Bearer` + `CSOR-Token` headers.
class OrderRepository {
  final ApiClient _api;
  OrderRepository(this._api);

  /// Submits a saved order; returns the raw response body on HTTP 2xx.
  Future<RepoResult<String>> submitSavedOrder({
    required SessionManager session,
    required PendingOrder order,
    required String deviceId,
    required String versionId,
  }) async {
    final authToken = session.getAuthToken();
    if (authToken == null || authToken.isEmpty) {
      return RepoResult.failure(StateError('Not logged in – auth token missing'));
    }
    final url = session.getOrderServiceUrl(order.orderType);
    if (url == null) {
      return RepoResult.failure(
          StateError('No URL configured for request type: ${order.orderType}'));
    }
    final payload = buildPayloadJson(
      order: order,
      deviceId: deviceId,
      versionId: versionId,
      buId: session.getBuId() ?? '',
      userId: session.getUserId() ?? order.storeId,
    );
    return _post(url, authToken, payload);
  }

  /// Pre-submit Order Minimum gate. Posts the same payload to the PRE-OM-CHECK
  /// URL and parses the shortfall response. Callers treat failure as fail-open.
  Future<RepoResult<PreOmCheckResult>> preOmCheck({
    required SessionManager session,
    required PendingOrder order,
    required String deviceId,
    required String versionId,
  }) async {
    final auth = session.getAuthToken();
    if (auth == null || auth.isEmpty) {
      return RepoResult.failure(StateError('auth token missing'));
    }
    final url = session.getOrderServiceUrl('PRE-OM-CHECK');
    if (url == null) return RepoResult.failure(StateError('no PRE-OM-CHECK url'));
    final payload = buildPayloadJson(
      order: order,
      deviceId: deviceId,
      versionId: versionId,
      buId: session.getBuId() ?? '',
      userId: session.getUserId() ?? order.storeId,
    );
    final raw = await _post(url, auth, payload);
    if (!raw.isSuccess) return RepoResult.failure(raw.error);
    try {
      final obj = jsonDecode(raw.value!) as Map<String, dynamic>;
      final data = (obj['data'] as List?) ?? const [];
      final first = data.isNotEmpty ? data.first as Map<String, dynamic> : null;
      final shortfall =
          (first?['shortFall'] ?? 'N').toString().trim().toUpperCase() == 'Y';
      return RepoResult.success(
          PreOmCheckResult(shortfall, (first?['response'] ?? '').toString()));
    } catch (e) {
      return RepoResult.failure(e);
    }
  }

  /// Pre-submit Recommended Items gate. Returns the recommended item list.
  Future<RepoResult<List<RecommendedItemEntry>>> preRecommendedItemsCheck({
    required SessionManager session,
    required PendingOrder order,
    required String deviceId,
    required String versionId,
  }) async {
    final auth = session.getAuthToken();
    if (auth == null || auth.isEmpty) {
      return RepoResult.failure(StateError('auth token missing'));
    }
    final url = session.getOrderServiceUrl('RECOMMENDED_ITEMS');
    if (url == null) return RepoResult.failure(StateError('no RECOMMENDED_ITEMS url'));
    final payload = buildPayloadJson(
      order: order,
      deviceId: deviceId,
      versionId: versionId,
      buId: session.getBuId() ?? '',
      userId: session.getUserId() ?? order.storeId,
    );
    final raw = await _post(url, auth, payload);
    if (!raw.isSuccess) return RepoResult.failure(raw.error);
    try {
      final obj = jsonDecode(raw.value!) as Map<String, dynamic>;
      // spec misspelling "recommenededItems" preserved.
      final list = (obj['recommenededItems'] as List?) ?? const [];
      final items = list
          .map((e) => RecommendedItemEntry(
                (e['itemNumber'] ?? '').toString(),
                (e['qty'] ?? '0').toString(),
              ))
          .toList();
      return RepoResult.success(items);
    } catch (e) {
      return RepoResult.failure(e);
    }
  }

  // ── Order Approval ──────────────────────────────────────────────────────────

  Future<RepoResult<ApprovalsListResponse>> fetchApprovals({
    required SessionManager session,
    required bool waiting,
    required String deviceId,
    required String versionId,
  }) async {
    final auth = session.getAuthToken();
    if (auth == null || auth.isEmpty) {
      return RepoResult.failure(StateError('auth token missing'));
    }
    final key = waiting ? 'WAITING_APPROVALS_LIST' : 'APPROVED_ORDERS_LIST';
    final url = session.getOrderServiceUrl(key);
    if (url == null) return RepoResult.failure(StateError('no $key url'));
    final payload = jsonEncode({
      'deviceId': deviceId,
      'storeId': session.getActiveStoreId(),
      'userName': session.getUserId() ?? '',
      'versionId': versionId,
    });
    final raw = await _post(url, auth, payload);
    if (!raw.isSuccess) return RepoResult.failure(raw.error);
    try {
      return RepoResult.success(
          ApprovalsListResponse.fromJson(jsonDecode(raw.value!) as Map<String, dynamic>));
    } catch (e) {
      return RepoResult.failure(e);
    }
  }

  Future<RepoResult<ApiItemOrder>> fetchApprovalOrder({
    required SessionManager session,
    required String confirmationId,
    required bool waiting,
    required String deviceId,
    required String versionId,
  }) async {
    final auth = session.getAuthToken();
    if (auth == null || auth.isEmpty) {
      return RepoResult.failure(StateError('auth token missing'));
    }
    final key = waiting ? 'ORDER_APPROVAL_DETAILS' : 'APPROVED_ORDER';
    final url = session.getOrderServiceUrl(key);
    if (url == null) return RepoResult.failure(StateError('no $key url'));
    final payload = jsonEncode({
      'deviceId': deviceId,
      'storeId': session.getActiveStoreId(),
      'userName': session.getUserId() ?? '',
      'versionId': versionId,
      'confirmationId': confirmationId,
    });
    final raw = await _post(url, auth, payload);
    if (!raw.isSuccess) return RepoResult.failure(raw.error);
    try {
      return RepoResult.success(
          ApiItemOrder.fromJson(jsonDecode(raw.value!) as Map<String, dynamic>));
    } catch (e) {
      return RepoResult.failure(e);
    }
  }

  Future<RepoResult<String>> deleteWaitingApprovals({
    required SessionManager session,
    required List<ApprovalOrderSummary> orders,
    required String deviceId,
    required String versionId,
  }) async {
    final auth = session.getAuthToken();
    if (auth == null || auth.isEmpty) {
      return RepoResult.failure(StateError('auth token missing'));
    }
    final url = session.getOrderServiceUrl('DELETE_WAITING_APPROVAL');
    if (url == null) return RepoResult.failure(StateError('no DELETE_WAITING_APPROVAL url'));
    final payload = jsonEncode({
      'header': {
        'deviceId': deviceId,
        'storeId': session.getActiveStoreId(),
        'userName': session.getUserId() ?? '',
        'versionId': versionId,
      },
      'orderList': orders
          .map((o) => {'confirmationId': o.confirmationId, 'department': o.department})
          .toList(),
    });
    return _post(url, auth, payload);
  }

  // ── Invoices ────────────────────────────────────────────────────────────────

  Future<RepoResult<InvoiceListResponse>> fetchInvoiceList({
    required SessionManager session,
    required String fromDate,
    required String toDate,
    required String invoiceNumber,
    required String deviceId,
    required String versionId,
  }) async {
    final auth = session.getAuthToken();
    if (auth == null || auth.isEmpty) {
      return RepoResult.failure(StateError('auth token missing'));
    }
    final url = session.getOrderServiceUrl('INVOICE_LIST');
    if (url == null) return RepoResult.failure(StateError('no INVOICE_LIST url'));
    final payload = jsonEncode({
      'deviceId': deviceId,
      'storeId': session.getActiveStoreId(),
      'userName': session.getUserId() ?? '',
      'versionId': versionId,
      'fromDate': fromDate,
      'toDate': toDate,
      'invoiceNumber': invoiceNumber,
    });
    final raw = await _post(url, auth, payload);
    if (!raw.isSuccess) return RepoResult.failure(raw.error);
    try {
      return RepoResult.success(
          InvoiceListResponse.fromJson(jsonDecode(raw.value!) as Map<String, dynamic>));
    } catch (e) {
      return RepoResult.failure(e);
    }
  }

  Future<RepoResult<InvoiceDetailResponse>> fetchInvoiceDetails({
    required SessionManager session,
    required String invoiceNumber,
    required String deviceId,
    required String versionId,
  }) async {
    final auth = session.getAuthToken();
    if (auth == null || auth.isEmpty) {
      return RepoResult.failure(StateError('auth token missing'));
    }
    final url = session.getOrderServiceUrl('INVOICE_DETAIL');
    if (url == null) return RepoResult.failure(StateError('no INVOICE_DETAIL url'));
    final payload = jsonEncode({
      'deviceId': deviceId,
      'storeId': session.getActiveStoreId(),
      'userName': session.getUserId() ?? '',
      'versionId': versionId,
      'invoiceNumber': invoiceNumber,
    });
    final raw = await _post(url, auth, payload);
    if (!raw.isSuccess) return RepoResult.failure(raw.error);
    try {
      return RepoResult.success(
          InvoiceDetailResponse.fromJson(jsonDecode(raw.value!) as Map<String, dynamic>));
    } catch (e) {
      return RepoResult.failure(e);
    }
  }

  /// Returns raw PDF bytes for an invoice (GET_INVOICE_PDF).
  Future<RepoResult<List<int>>> fetchInvoicePdf({
    required SessionManager session,
    required String invoiceNumber,
    required String deviceId,
    required String versionId,
  }) async {
    final auth = session.getAuthToken();
    if (auth == null || auth.isEmpty) {
      return RepoResult.failure(StateError('auth token missing'));
    }
    final url = session.getOrderServiceUrl('GET_INVOICE_PDF');
    if (url == null) return RepoResult.failure(StateError('no GET_INVOICE_PDF url'));
    final payload = jsonEncode({
      'deviceId': deviceId,
      'storeId': session.getActiveStoreId(),
      'userName': session.getUserId() ?? '',
      'versionId': versionId,
      'invoiceNumber': invoiceNumber,
    });
    try {
      final res = await _api.dio.post(
        url,
        data: payload,
        options: Options(
          contentType: Headers.jsonContentType,
          responseType: ResponseType.bytes,
          headers: {
            'Authorization': 'Bearer $auth',
            'CSOR-Token': auth,
            'Accept': 'application/octet-stream',
          },
        ),
      );
      final code = res.statusCode ?? 0;
      if (code < 200 || code >= 300) {
        return RepoResult.failure(StateError('HTTP $code'));
      }
      final data = res.data;
      return RepoResult.success(data is List<int> ? data : <int>[]);
    } catch (e) {
      return RepoResult.failure(e);
    }
  }

  // ── Standing / favourite orders ──────────────────────────────────────────────

  Future<RepoResult<List<String>>> fetchFavouriteOrderNames({
    required SessionManager session,
    required String storeId,
    required String deviceId,
    required String versionId,
  }) async {
    final auth = session.getAuthToken();
    if (auth == null || auth.isEmpty) return RepoResult.failure(StateError('auth missing'));
    final url = session.getOrderServiceUrl('FETCH_FAVOURITE_ORDER_NAMES-FVORDNAMES');
    if (url == null) return RepoResult.failure(StateError('no favourite-names url'));
    final payload = jsonEncode({
      'customerStoreNumber': storeId,
      'deviceId': deviceId,
      'userName': session.getUserId() ?? '',
      'versionId': versionId,
    });
    final raw = await _post(url, auth, payload);
    if (!raw.isSuccess) return RepoResult.failure(raw.error);
    try {
      final obj = jsonDecode(raw.value!) as Map<String, dynamic>;
      final names = ((obj['orderNames'] as List?) ?? const []).map((e) => e.toString()).toList();
      return RepoResult.success(names);
    } catch (e) {
      return RepoResult.failure(e);
    }
  }

  /// Returns the template's lines as (itemNumber, qty) pairs.
  Future<RepoResult<List<MapEntry<String, String>>>> fetchFavouriteOrder({
    required SessionManager session,
    required String orderName,
    required String storeId,
    required String deviceId,
    required String versionId,
  }) async {
    final auth = session.getAuthToken();
    if (auth == null || auth.isEmpty) return RepoResult.failure(StateError('auth missing'));
    final url = session.getOrderServiceUrl('FETCH_FAVOURITE_ORDERS-FVORDFETCH');
    if (url == null) return RepoResult.failure(StateError('no favourite-fetch url'));
    final payload = jsonEncode({
      'orderName': orderName,
      'customerStoreNumber': storeId,
      'deviceId': deviceId,
      'userName': session.getUserId() ?? '',
      'versionId': versionId,
    });
    final raw = await _post(url, auth, payload);
    if (!raw.isSuccess) return RepoResult.failure(raw.error);
    try {
      final obj = jsonDecode(raw.value!) as Map<String, dynamic>;
      final details = ((obj['orderDetails'] as List?) ?? const [])
          .map((e) => MapEntry(
              (e['itemNumber'] ?? '').toString(), (e['quantity'] ?? '').toString()))
          .toList();
      return RepoResult.success(details);
    } catch (e) {
      return RepoResult.failure(e);
    }
  }

  Future<RepoResult<String>> saveFavouriteOrder({
    required SessionManager session,
    required String orderName,
    required String poNumber,
    required String deliveryDate,
    required String comments,
    required String storeId,
    required String deviceId,
    required String versionId,
    required List<MapEntry<String, String>> lines, // (itemNumber, qty)
  }) async {
    final auth = session.getAuthToken();
    if (auth == null || auth.isEmpty) return RepoResult.failure(StateError('auth missing'));
    final url = session.getOrderServiceUrl('SAVE_FAVOURITE_ORDER-FVORDSAVE');
    if (url == null) return RepoResult.failure(StateError('no favourite-save url'));
    final payload = jsonEncode({
      'orderName': orderName,
      'orderHeader': {
        'custPoNumber': poNumber,
        'requestedDeliveryDate': _formatDeliveryDate(deliveryDate),
        'customerStoreNumber': storeId,
        'deviceId': deviceId,
        'requestType': 'ITEM_ORDER',
        'buId': session.getBuId() ?? '',
        'comment': comments,
        'orderType': '00',
      },
      'orderDetails':
          lines.map((e) => {'itemNumber': e.key, 'quantity': e.value}).toList(),
    });
    return _post(url, auth, payload);
  }

  Future<RepoResult<String>> deleteFavouriteOrder({
    required SessionManager session,
    required String orderName,
    required String storeId,
    required String deviceId,
    required String versionId,
  }) async {
    final auth = session.getAuthToken();
    if (auth == null || auth.isEmpty) return RepoResult.failure(StateError('auth missing'));
    final url = session.getOrderServiceUrl('DELETE_FAVOURITE_ORDER-FVORDDELETE');
    if (url == null) return RepoResult.failure(StateError('no favourite-delete url'));
    final payload = jsonEncode({
      'orderName': orderName,
      'customerStoreNumber': storeId,
      'deviceId': deviceId,
      'userName': session.getUserId() ?? '',
      'versionId': versionId,
    });
    return _post(url, auth, payload);
  }

  // ── Store-order history ───────────────────────────────────────────────────────

  Future<RepoResult<RecentOrdersResponse>> fetchRecentOrders({
    required SessionManager session,
    required String storeId,
    required String deviceId,
    required String versionId,
    String? fromDate,
    String? toDate,
    String? confirmationId,
  }) async {
    final auth = session.getAuthToken();
    if (auth == null || auth.isEmpty) return RepoResult.failure(StateError('auth missing'));
    final url = session.getServiceUrl('RECENT_ORDERS-RESPONSE3');
    if (url == null) return RepoResult.failure(StateError('no recent-orders url'));
    final payload = jsonEncode({
      if (fromDate != null && fromDate.isNotEmpty) 'fromDate': fromDate,
      if (toDate != null && toDate.isNotEmpty) 'toDate': toDate,
      if (confirmationId != null && confirmationId.isNotEmpty)
        'confirmationId': confirmationId,
      'storeId': storeId,
      'deviceId': deviceId,
      'userName': session.getUserId() ?? '',
      'versionId': versionId,
      'appOS': 'Android',
    });
    final raw = await _post(url, auth, payload);
    if (!raw.isSuccess) return RepoResult.failure(raw.error);
    try {
      return RepoResult.success(
          RecentOrdersResponse.fromJson(jsonDecode(raw.value!) as Map<String, dynamic>));
    } catch (e) {
      return RepoResult.failure(e);
    }
  }

  Future<RepoResult<StoreOrderDetailResponse>> retrieveStoreOrderDetail({
    required SessionManager session,
    required String storeId,
    required String confirmationId,
    required String transactionId,
    required String deviceId,
    required String versionId,
  }) async {
    final auth = session.getAuthToken();
    if (auth == null || auth.isEmpty) return RepoResult.failure(StateError('auth missing'));
    final url = session.getServiceUrl('RETRIEVE_ORDER-RESPONSE1');
    if (url == null) return RepoResult.failure(StateError('no retrieve-order url'));
    final payload = jsonEncode({
      'header': {
        'storeId': storeId,
        'userName': session.getUserId() ?? '',
        'versionId': versionId,
        'appOS': 'Android',
      },
      'data': {'confirmationId': confirmationId, 'transactionId': transactionId},
    });
    final raw = await _post(url, auth, payload);
    if (!raw.isSuccess) return RepoResult.failure(raw.error);
    try {
      return RepoResult.success(
          StoreOrderDetailResponse.fromJson(jsonDecode(raw.value!) as Map<String, dynamic>));
    } catch (e) {
      return RepoResult.failure(e);
    }
  }

  Future<RepoResult<String>> _post(
      String url, String authToken, String payloadJson) async {
    try {
      final res = await _api.dio.post(
        url,
        data: payloadJson,
        options: Options(
          contentType: Headers.jsonContentType,
          responseType: ResponseType.plain,
          headers: {
            'Authorization': 'Bearer $authToken',
            'CSOR-Token': authToken,
          },
        ),
      );
      final body = (res.data ?? '').toString();
      final code = res.statusCode ?? 0;
      if (code >= 200 && code < 300) return RepoResult.success(body);
      return RepoResult.failure(StateError('HTTP $code\n${_take(body, 500)}'));
    } catch (e) {
      return RepoResult.failure(e);
    }
  }

  // ── Payload builder (faithful to buildPayloadJson) ──────────────────────────

  String buildPayloadJson({
    required PendingOrder order,
    required String deviceId,
    required String versionId,
    required String buId,
    required String userId,
  }) {
    final savedLines = _decodeLines(order.linesJson);
    final header = {'userName': userId, 'versionId': versionId, 'appOS': 'Android'};
    final deliveryDate = _formatDeliveryDate(order.deliveryDate);
    final requestType = order.orderType;
    final isCredit = requestType == 'CREDIT_REQUEST';
    final isPriceChange = requestType == 'PRICE_CHANGE' || requestType == 'TPR';

    // Group lines by the partition active when added (fallback to order-level).
    Map<String, List<SavedOrderLine>> groupByPartition() {
      final map = <String, List<SavedOrderLine>>{};
      for (final l in savedLines) {
        final key = l.partition.isNotEmpty ? l.partition : order.partition;
        (map[key] ??= []).add(l);
      }
      return map;
    }

    Map<String, dynamic> summaryOf(List<SavedOrderLine> lines) {
      final items = lines.where((l) => (int.tryParse(l.qty) ?? 0) >= 1).length;
      final qty = lines.fold<int>(0, (a, l) => a + (int.tryParse(l.qty) ?? 0));
      final value = lines.fold<double>(
          0, (a, l) => a + (double.tryParse(l.estimatedValue) ?? 0));
      final cube = lines.fold<double>(
          0,
          (a, l) =>
              a + (double.tryParse(l.qty) ?? 0) * (double.tryParse(l.cube) ?? 0));
      return {
        'totalItems': '$items',
        'totalCaseQty': '$qty',
        'totalEstimateValue': value.toStringAsFixed(2),
        'totalAllowanceValue': '0',
        'totalCube': cube.toStringAsFixed(2),
      };
    }

    Map<String, dynamic> orderHeaderMap(String partitionKey, List<SavedOrderLine> g) => {
          'custPoNumber': order.poNumber,
          'requestedDeliveryDate': deliveryDate,
          'customerStoreNumber': order.storeId,
          'deviceId': deviceId,
          'requestType': requestType,
          'buId': buId,
          'comment': order.comments,
          'storePartition': partitionKey,
          'custTransmissionSummary': summaryOf(g),
          'adDate': order.adDate,
          'adId': order.adId,
          'data1': order.data1,
          'data2': order.data2,
          'data3': order.data3,
          'date1': order.date1,
          'date2': order.date2,
        };

    if (isCredit) {
      final orderRequest = groupByPartition().entries.map((e) {
        return {
          'orderHeader': orderHeaderMap(e.key, e.value),
          'orderDetails': e.value
              .map((l) => {
                    'itemNumber': l.itemNumber,
                    'itemDescription': l.itemDescription,
                    'storeDepartment':
                        l.storeDepartment.isNotEmpty ? l.storeDepartment : e.key,
                    'quantity': l.qty,
                    'crReasonCode': l.crReasonCode,
                    'crType': l.crType,
                    'crInvoiceNumber': l.crInvoiceNumber,
                    'itemUpc': l.upc.isNotEmpty ? l.upc : '0',
                  })
              .toList(),
        };
      }).toList();
      return jsonEncode({'header': header, 'orderRequest': orderRequest});
    }

    if (isPriceChange) {
      final pcHeader = {
        'custPoNumber': order.poNumber,
        'requestedDeliveryDate': deliveryDate,
        'customerStoreNumber': order.storeId,
        'deviceId': deviceId,
        'requestType': requestType,
        'buId': buId,
        'storePartition': order.partition,
        'comment': order.comments,
        'adDate': order.adDate,
        'adId': order.adId,
        'data1': order.data1,
        'data2': order.data2,
        'data3': order.data3,
        'date1': order.date1,
        'date2': order.date2,
      };
      final pcDetails = savedLines
          .map((l) => {
                'itemNumber': l.itemNumber,
                'quantity': l.qty,
                'price': l.newPrice.isNotEmpty ? l.newPrice : '0',
                'fromDate': l.fromDate,
                'toDate': l.toDate,
                'grossMargin': '',
              })
          .toList();
      return jsonEncode({'header': header, 'pcHeader': pcHeader, 'pcDetails': pcDetails});
    }

    // ITEM_ORDER / AD_ORDER / TAG_ORDER / TOBACCO
    final orderRequest = groupByPartition().entries.map((e) {
      return {
        'orderHeader': orderHeaderMap(e.key, e.value),
        'orderDetails': e.value
            .map((l) => {
                  'itemNumber': l.itemNumber,
                  'itemDescription': l.itemDescription,
                  'storeDepartment':
                      l.storeDepartment.isNotEmpty ? l.storeDepartment : e.key,
                  'quantity': l.qty,
                  'tagRequired': l.tagRequired,
                  'itemUpc': l.upc.isNotEmpty ? l.upc : '0',
                  'itemCodeMults': l.itemCodeMults,
                })
            .toList(),
      };
    }).toList();
    return jsonEncode({'header': header, 'orderRequest': orderRequest});
  }

  List<SavedOrderLine> _decodeLines(String linesJson) {
    try {
      final list = jsonDecode(linesJson) as List;
      return list
          .map((e) => SavedOrderLine.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// MM/DD/YYYY or YYYY-MM-DD → MMDDYYYY.
  String _formatDeliveryDate(String date) {
    if (date.trim().isEmpty) return '';
    final slash = date.replaceAll('/', '');
    if (slash.length == 8 && slash.split('').every((c) => '0123456789'.contains(c))) {
      return slash;
    }
    final parts = date.split('-');
    if (parts.length == 3) {
      final y = parts[0], m = parts[1], d = parts[2];
      return '$m$d$y'.replaceAll(RegExp(r'\D'), '');
    }
    return date.replaceAll(RegExp(r'\D'), '');
  }

  String _take(String s, int n) => s.length <= n ? s : s.substring(0, n);
}
