import 'package:sqflite/sqflite.dart';

import 'app_database.dart';
import 'message.dart';

/// DAO for `messages` (port of Room MessageDao).
class MessageDao {
  Future<List<MessageRow>> getAllMessages() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('messages', orderBy: 'receivedAt DESC');
    return rows.map(MessageRow.fromMap).toList();
  }

  Future<List<MessageRow>> getMessagesByGroup(String group) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('messages',
        where: 'notificationType = ?', whereArgs: [group], orderBy: 'receivedAt DESC');
    return rows.map(MessageRow.fromMap).toList();
  }

  Future<MessageRow?> getByKey(String key) async {
    final db = await AppDatabase.instance.database;
    final rows =
        await db.query('messages', where: 'messageKey = ?', whereArgs: [key], limit: 1);
    return rows.isEmpty ? null : MessageRow.fromMap(rows.first);
  }

  Future<int> totalUnread() async {
    final db = await AppDatabase.instance.database;
    final r = await db.rawQuery('SELECT COUNT(*) c FROM messages WHERE isRead = 0');
    return (r.first['c'] as int?) ?? 0;
  }

  Future<Map<String, int>> unreadByGroup() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery(
        'SELECT notificationType t, COUNT(*) c FROM messages WHERE isRead = 0 GROUP BY notificationType');
    return {for (final r in rows) (r['t'] ?? '') as String: (r['c'] as int?) ?? 0};
  }

  Future<int> unreadImportant() async {
    final db = await AppDatabase.instance.database;
    final r = await db.rawQuery(
        "SELECT COUNT(*) c FROM messages WHERE notificationType = 'IMPORTANT' AND isRead = 0");
    return (r.first['c'] as int?) ?? 0;
  }

  Future<void> markAsRead(String messageKey) async {
    final db = await AppDatabase.instance.database;
    await db.update('messages', {'isRead': 1},
        where: 'messageKey = ?', whereArgs: [messageKey]);
  }

  /// Insert new messages without overwriting locally-read ones (IGNORE on PK).
  Future<void> insertNew(List<MessageRow> messages) async {
    final db = await AppDatabase.instance.database;
    final batch = db.batch();
    for (final m in messages) {
      batch.insert('messages', m.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }
}
