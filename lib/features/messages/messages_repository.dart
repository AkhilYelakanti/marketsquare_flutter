import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/device_meta.dart';
import '../../data/db/message.dart';
import '../../data/db/message_dao.dart';
import '../../data/session/session_manager.dart';

/// Port of `MessagesRepository`: pulls messages from the server into the local
/// `messages` table and sends read receipts. Groups by `deptQueue`
/// (notificationType). No-ops gracefully when endpoints aren't configured.
class MessagesRepository {
  final SessionManager session;
  final MessageDao dao;
  final Dio _dio;

  MessagesRepository(this.session, {MessageDao? dao, Dio? dio})
      : dao = dao ?? MessageDao(),
        _dio = dio ?? Dio(BaseOptions(validateStatus: (_) => true));

  Future<int> pullMessages() => _post('PULL_MESSAGES-PULLMSG');
  Future<int> refreshMessages() => _post('REFRESH_MESSAGES-REFRESHMSG');

  Future<int> _post(String key) async {
    final url = session.getServiceUrl(key);
    final token = session.getAuthToken();
    if (url == null || url.isEmpty || token == null || token.isEmpty) return 0;
    try {
      final payload = jsonEncode({
        'deviceId': await deviceId(),
        'storeId': session.getActiveStoreId(),
        'userName': session.getUserId() ?? '',
        'versionId': await versionId(),
      });
      final res = await _dio.post(url,
          data: payload,
          options: Options(
            contentType: Headers.jsonContentType,
            responseType: ResponseType.plain,
            headers: {'Authorization': 'Bearer $token', 'CSOR-Token': token},
          ));
      final code = res.statusCode ?? 0;
      if (code < 200 || code >= 300) return 0;
      final obj = jsonDecode((res.data ?? '{}').toString()) as Map<String, dynamic>;
      final list = (obj['pullMessages'] as List?) ?? const [];
      final rows = list.map((e) => _toRow(e as Map<String, dynamic>)).toList();
      if (rows.isNotEmpty) await dao.insertNew(rows);
      return rows.length;
    } catch (_) {
      return 0;
    }
  }

  Future<void> sendReadReceipt(String messageKey, String? notificationId) async {
    await dao.markAsRead(messageKey);
    if (notificationId == null || notificationId.isEmpty) return;
    final url = session.getServiceUrl('MESSAGE_READ_RECEIPT');
    final token = session.getAuthToken();
    if (url == null || url.isEmpty || token == null || token.isEmpty) return;
    try {
      final now = DateTime.now();
      String two(int n) => n.toString().padLeft(2, '0');
      final readTime =
          '${now.year}-${two(now.month)}-${two(now.day)} ${two(now.hour)}:${two(now.minute)}:${two(now.second)}';
      await _dio.post(url,
          data: jsonEncode({
            'deviceId': await deviceId(),
            'storeId': session.getActiveStoreId(),
            'userName': session.getUserId() ?? '',
            'versionId': await versionId(),
            'msgId': notificationId,
            'messageReadTime': readTime,
            'msgStatus': 'Read',
          }),
          options: Options(
            contentType: Headers.jsonContentType,
            headers: {'Authorization': 'Bearer $token', 'CSOR-Token': token},
          ));
    } catch (_) {/* best effort */}
  }

  MessageRow _toRow(Map<String, dynamic> j) {
    final notifId = (j['msgId'] ?? '').toString();
    final storeId = (j['storeId'] ?? '').toString();
    final lastComm = (j['lastComm'] ?? '').toString();
    final dept = (j['deptQueue'] ?? '').toString();
    final key = notifId.isNotEmpty
        ? notifId
        : '${storeId}_${lastComm}_$dept'.replaceAll(' ', '_');
    return MessageRow(
      messageKey: key,
      notificationId: notifId.isEmpty ? null : notifId,
      convId: (j['convId'] ?? notifId).toString(),
      storeId: storeId,
      storeName: (j['storeName'] ?? '').toString(),
      messageBody: (j['msgText'] ?? '').toString(),
      contactName: (j['msgOwner'] ?? '').toString(),
      lastCommunicationDate: lastComm,
      notificationType: dept,
      isRead: false,
      receivedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }
}
