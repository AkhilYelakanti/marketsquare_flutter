/// Port of Room `MessageEntity`.
class MessageRow {
  final String messageKey;
  final String? notificationId;
  final String convId;
  final String storeId;
  final String storeName;
  final String messageBody;
  final String contactName;
  final String lastCommunicationDate;
  final String notificationType; // group (deptQueue)
  final bool isRead;
  final int receivedAt;

  const MessageRow({
    required this.messageKey,
    this.notificationId,
    this.convId = '',
    this.storeId = '',
    this.storeName = '',
    this.messageBody = '',
    this.contactName = '',
    this.lastCommunicationDate = '',
    this.notificationType = '',
    this.isRead = false,
    this.receivedAt = 0,
  });

  Map<String, Object?> toMap() => {
        'messageKey': messageKey,
        'notificationId': notificationId,
        'convId': convId,
        'storeId': storeId,
        'storeName': storeName,
        'messageBody': messageBody,
        'contactName': contactName,
        'lastCommunicationDate': lastCommunicationDate,
        'notificationType': notificationType,
        'isRead': isRead ? 1 : 0,
        'receivedAt': receivedAt,
      };

  factory MessageRow.fromMap(Map<String, Object?> m) => MessageRow(
        messageKey: (m['messageKey'] ?? '') as String,
        notificationId: m['notificationId'] as String?,
        convId: (m['convId'] ?? '') as String,
        storeId: (m['storeId'] ?? '') as String,
        storeName: (m['storeName'] ?? '') as String,
        messageBody: (m['messageBody'] ?? '') as String,
        contactName: (m['contactName'] ?? '') as String,
        lastCommunicationDate: (m['lastCommunicationDate'] ?? '') as String,
        notificationType: (m['notificationType'] ?? '') as String,
        isRead: ((m['isRead'] as int?) ?? 0) == 1,
        receivedAt: (m['receivedAt'] as int?) ?? 0,
      );
}
