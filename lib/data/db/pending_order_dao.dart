import 'app_database.dart';
import 'pending_order.dart';

/// DAO for the `pending_orders` table (port of Room PendingOrderDao).
class PendingOrderDao {
  Future<int> insert(PendingOrder order) async {
    final db = await AppDatabase.instance.database;
    return db.insert('pending_orders', order.toMap());
  }

  Future<PendingOrder?> getById(int id) async {
    final db = await AppDatabase.instance.database;
    final rows =
        await db.query('pending_orders', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : PendingOrder.fromMap(rows.first);
  }

  Future<void> deleteById(int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('pending_orders', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<PendingOrder>> listByStatus(String status) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('pending_orders',
        where: 'status = ?', whereArgs: [status], orderBy: 'createdAt DESC');
    return rows.map(PendingOrder.fromMap).toList();
  }

  Future<List<PendingOrder>> listAll() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('pending_orders', orderBy: 'createdAt DESC');
    return rows.map(PendingOrder.fromMap).toList();
  }

  Future<List<PendingOrder>> getUnsent() => listByStatus('UNSENT');

  /// Replaces a row (used to append recommended items to its linesJson).
  Future<void> update(PendingOrder order) async {
    final db = await AppDatabase.instance.database;
    await db.update('pending_orders', order.toMap(),
        where: 'id = ?', whereArgs: [order.id]);
  }

  /// Marks an order SENT with its confirmation number.
  Future<void> markSent(int id, int sentAt, String confirmationNumber) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'pending_orders',
      {'status': 'SENT', 'sentAt': sentAt, 'confirmationNumber': confirmationNumber},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
