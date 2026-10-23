/// Port of Room `BackroomItemEntity`.
class BackroomItem {
  final int id;
  final String department;
  final String itemCode;
  final String itemDescription;
  final int quantity;
  final int createdAt;
  final int updatedAt;

  const BackroomItem({
    this.id = 0,
    this.department = '',
    this.itemCode = '',
    this.itemDescription = '',
    this.quantity = 0,
    this.createdAt = 0,
    this.updatedAt = 0,
  });

  BackroomItem copyWith({int? quantity, String? itemDescription, int? updatedAt}) =>
      BackroomItem(
        id: id,
        department: department,
        itemCode: itemCode,
        itemDescription: itemDescription ?? this.itemDescription,
        quantity: quantity ?? this.quantity,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, Object?> toMap() => {
        if (id != 0) 'id': id,
        'department': department,
        'itemCode': itemCode,
        'itemDescription': itemDescription,
        'quantity': quantity,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  factory BackroomItem.fromMap(Map<String, Object?> m) => BackroomItem(
        id: (m['id'] as int?) ?? 0,
        department: (m['department'] ?? '') as String,
        itemCode: (m['itemCode'] ?? '') as String,
        itemDescription: (m['itemDescription'] ?? '') as String,
        quantity: (m['quantity'] as int?) ?? 0,
        createdAt: (m['createdAt'] as int?) ?? 0,
        updatedAt: (m['updatedAt'] as int?) ?? 0,
      );
}
