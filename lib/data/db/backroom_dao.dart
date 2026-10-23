import 'package:sqflite/sqflite.dart';

import 'app_database.dart';
import 'backroom_item.dart';

/// DAO for `backroom_inventory` (port of Room BackroomItemDao).
class BackroomDao {
  Future<List<BackroomItem>> getByDepartment(String dept) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('backroom_inventory',
        where: 'department = ?', whereArgs: [dept], orderBy: 'itemCode ASC');
    return rows.map(BackroomItem.fromMap).toList();
  }

  Future<List<BackroomItem>> getAll() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('backroom_inventory',
        orderBy: 'department ASC, itemCode ASC');
    return rows.map(BackroomItem.fromMap).toList();
  }

  Future<BackroomItem?> getByDeptAndCode(String dept, String itemCode) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('backroom_inventory',
        where: 'department = ? AND itemCode = ?',
        whereArgs: [dept, itemCode],
        limit: 1);
    return rows.isEmpty ? null : BackroomItem.fromMap(rows.first);
  }

  Future<int> insert(BackroomItem item) async {
    final db = await AppDatabase.instance.database;
    return db.insert('backroom_inventory', item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> update(BackroomItem item) async {
    final db = await AppDatabase.instance.database;
    await db.update('backroom_inventory', item.toMap(),
        where: 'id = ?', whereArgs: [item.id]);
  }

  Future<void> deleteByDepartment(String dept) async {
    final db = await AppDatabase.instance.database;
    await db.delete('backroom_inventory', where: 'department = ?', whereArgs: [dept]);
  }

  Future<void> deleteAll() async {
    final db = await AppDatabase.instance.database;
    await db.delete('backroom_inventory');
  }

  Future<void> deleteById(int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('backroom_inventory', where: 'id = ?', whereArgs: [id]);
  }
}
