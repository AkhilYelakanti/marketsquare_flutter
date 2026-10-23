/// Port of Room `PendingOrderEntity`. Persisted in the local SQLite
/// `pending_orders` table; [linesJson] holds the serialized SavedOrderLine list.
class PendingOrder {
  final int id;
  final String storeId;
  final String orderType;
  final String partition;
  final String poNumber;
  final String comments;
  final String deliveryDate;
  final String adDate;
  final String adId;
  final String data1;
  final String data2;
  final String data3;
  final String date1;
  final String date2;
  final String status; // UNSENT | SENT | ...
  final String linesJson;
  final int itemCount;
  final int totalQty;
  final String totalValue;
  final String totalCube;
  final int createdAt;
  final int sentAt;
  final String confirmationNumber;

  const PendingOrder({
    this.id = 0,
    this.storeId = '',
    this.orderType = '',
    this.partition = '',
    this.poNumber = '',
    this.comments = '',
    this.deliveryDate = '',
    this.adDate = '',
    this.adId = '',
    this.data1 = '',
    this.data2 = '',
    this.data3 = '',
    this.date1 = '',
    this.date2 = '',
    this.status = 'UNSENT',
    this.linesJson = '[]',
    this.itemCount = 0,
    this.totalQty = 0,
    this.totalValue = '0.00',
    this.totalCube = '0.00',
    this.createdAt = 0,
    this.sentAt = 0,
    this.confirmationNumber = '',
  });

  Map<String, Object?> toMap() => {
        if (id != 0) 'id': id,
        'storeId': storeId,
        'orderType': orderType,
        'partition': partition,
        'poNumber': poNumber,
        'comments': comments,
        'deliveryDate': deliveryDate,
        'adDate': adDate,
        'adId': adId,
        'data1': data1,
        'data2': data2,
        'data3': data3,
        'date1': date1,
        'date2': date2,
        'status': status,
        'linesJson': linesJson,
        'itemCount': itemCount,
        'totalQty': totalQty,
        'totalValue': totalValue,
        'totalCube': totalCube,
        'createdAt': createdAt,
        'sentAt': sentAt,
        'confirmationNumber': confirmationNumber,
      };

  factory PendingOrder.fromMap(Map<String, Object?> m) => PendingOrder(
        id: (m['id'] as int?) ?? 0,
        storeId: (m['storeId'] ?? '') as String,
        orderType: (m['orderType'] ?? '') as String,
        partition: (m['partition'] ?? '') as String,
        poNumber: (m['poNumber'] ?? '') as String,
        comments: (m['comments'] ?? '') as String,
        deliveryDate: (m['deliveryDate'] ?? '') as String,
        adDate: (m['adDate'] ?? '') as String,
        adId: (m['adId'] ?? '') as String,
        data1: (m['data1'] ?? '') as String,
        data2: (m['data2'] ?? '') as String,
        data3: (m['data3'] ?? '') as String,
        date1: (m['date1'] ?? '') as String,
        date2: (m['date2'] ?? '') as String,
        status: (m['status'] ?? 'UNSENT') as String,
        linesJson: (m['linesJson'] ?? '[]') as String,
        itemCount: (m['itemCount'] as int?) ?? 0,
        totalQty: (m['totalQty'] as int?) ?? 0,
        totalValue: (m['totalValue'] ?? '0.00') as String,
        totalCube: (m['totalCube'] ?? '0.00') as String,
        createdAt: (m['createdAt'] as int?) ?? 0,
        sentAt: (m['sentAt'] as int?) ?? 0,
        confirmationNumber: (m['confirmationNumber'] ?? '') as String,
      );
}
