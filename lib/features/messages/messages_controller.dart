import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/message.dart';
import '../../data/db/message_dao.dart';
import '../../data/session/session_providers.dart';
import '../orderentry/alert_pipeline.dart';
import '../orderentry/order_entry_controller.dart';
import 'messages_repository.dart';

class MessageGroup {
  final String name;
  final int unreadCount;
  const MessageGroup(this.name, this.unreadCount);
}

class MessagesState {
  final List<MessageGroup> groups;
  final int totalUnread;
  final List<MessageRow> currentMessages; // messages for the open group / all
  final bool loading;
  final AlertMessagesConfig? importantAlert; // set when a mandatory IMPORTANT alert is due
  const MessagesState({
    this.groups = const [],
    this.totalUnread = 0,
    this.currentMessages = const [],
    this.loading = false,
    this.importantAlert,
  });
  MessagesState copyWith({
    List<MessageGroup>? groups,
    int? totalUnread,
    List<MessageRow>? currentMessages,
    bool? loading,
    AlertMessagesConfig? importantAlert,
    bool clearImportant = false,
  }) =>
      MessagesState(
        groups: groups ?? this.groups,
        totalUnread: totalUnread ?? this.totalUnread,
        currentMessages: currentMessages ?? this.currentMessages,
        loading: loading ?? this.loading,
        importantAlert: clearImportant ? null : (importantAlert ?? this.importantAlert),
      );
}

/// Port of `MessagesViewModel` (list/detail; polling replaced by pull-on-open).
class MessagesController extends Notifier<MessagesState> {
  static const _defaultSubjects = [
    'TECH_ISSUE', 'IMPORTANT', 'RECALL', 'MESSAGE:', 'ORDER_STATUS', 'GENERAL',
  ];

  final _dao = MessageDao();
  late final MessagesRepository _repo =
      MessagesRepository(ref.read(sessionManagerProvider), dao: _dao);

  @override
  MessagesState build() => const MessagesState();

  /// Pull from server (best-effort) then refresh local counts.
  Future<void> load() async {
    state = state.copyWith(loading: true);
    await _repo.pullMessages();
    await _refreshCounts();
    state = state.copyWith(loading: false);
  }

  Future<void> _refreshCounts() async {
    final session = ref.read(sessionManagerProvider);
    final unread = await _dao.unreadByGroup();
    final isRep = session.isRepAccount();
    final subjects = session.getMessagesSubjects();
    final groups = (subjects.isNotEmpty ? subjects : _defaultSubjects)
        .map((s) => MessageGroup(s, unread[s] ?? 0))
        .toList();
    final total = groups.fold<int>(0, (a, g) => a + g.unreadCount);
    state = state.copyWith(groups: groups, totalUnread: isRep ? 0 : total);
  }

  Future<List<MessageRow>> messagesForGroup(String group) =>
      _dao.getMessagesByGroup(group);

  Future<List<MessageRow>> allMessages() => _dao.getAllMessages();

  /// Marks a message read (local + receipt) and refreshes counts.
  Future<void> openMessage(MessageRow msg) async {
    if (!msg.isRead) {
      await _repo.sendReadReceipt(msg.messageKey, msg.notificationId);
      await _refreshCounts();
    }
  }

  /// Persists an inbound FCM data message into the local table, then refreshes
  /// counts and re-checks the mandatory IMPORTANT alert. No-ops for data that
  /// carries no message content (e.g. a pure deep-link payload).
  Future<void> ingestPushMessage(Map<String, dynamic> data) async {
    final body = (data['msgText'] ?? data['body'] ?? data['message'] ?? '').toString();
    final type = (data['deptQueue'] ?? data['notificationType'] ?? data['subject'] ?? '')
        .toString();
    if (body.isEmpty && type.isEmpty) return; // nothing message-like
    final notifId = (data['msgId'] ?? '').toString();
    final storeId = (data['storeId'] ?? '').toString();
    final lastComm = (data['lastComm'] ?? '').toString();
    final key = notifId.isNotEmpty
        ? notifId
        : '${storeId}_${lastComm}_$type'.replaceAll(' ', '_');
    await _dao.insertNew([
      MessageRow(
        messageKey: key,
        notificationId: notifId.isEmpty ? null : notifId,
        convId: (data['convId'] ?? notifId).toString(),
        storeId: storeId,
        storeName: (data['storeName'] ?? '').toString(),
        messageBody: body,
        contactName: (data['msgOwner'] ?? data['from'] ?? '').toString(),
        lastCommunicationDate: lastComm,
        notificationType: type.isEmpty ? 'GENERAL' : type,
        isRead: false,
        receivedAt: DateTime.now().millisecondsSinceEpoch,
      )
    ]);
    await _refreshCounts();
    await checkImportant();
  }

  /// Raises the mandatory IMPORTANT alert when there is an unread IMPORTANT
  /// message and LOV1 configures `MESSAGE_IMPORTANT` with alertNeeded = Y.
  Future<void> checkImportant() async {
    if (state.importantAlert != null) return;
    final unread = await _dao.unreadImportant();
    if (unread <= 0) return;
    final cfg = ref.read(orderEntryControllerProvider).config.alertMessagesConfigs.firstWhere(
          (c) =>
              c.alertType.toUpperCase() == 'MESSAGE_IMPORTANT' &&
              c.alertNeeded.toUpperCase() == 'Y',
          orElse: () => const AlertMessagesConfig(alertType: '__none__'),
        );
    if (cfg.alertType != '__none__') {
      state = state.copyWith(importantAlert: cfg);
    }
  }

  void dismissImportant() => state = state.copyWith(clearImportant: true);
}

final messagesControllerProvider =
    NotifierProvider<MessagesController, MessagesState>(MessagesController.new);

/// Unread badge count for the dashboard tile.
final messagesUnreadProvider = FutureProvider.autoDispose<int>((ref) async {
  final isRep = ref.read(sessionManagerProvider).isRepAccount();
  if (isRep) return 0;
  return MessageDao().totalUnread();
});
