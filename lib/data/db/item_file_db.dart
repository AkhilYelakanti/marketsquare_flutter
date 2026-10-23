import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:sqflite/sqflite.dart';

import 'app_database.dart';

/// Metadata snapshot for the dynamic item table (port of RefreshMetadataEntity).
class ItemFileMetadata {
  final List<String> columns;
  final String itemColName;
  final String deptColName;
  final int recordCount;
  final String lastUpdated;
  const ItemFileMetadata({
    this.columns = const [],
    this.itemColName = '',
    this.deptColName = '',
    this.recordCount = 0,
    this.lastUpdated = '',
  });
}

/// Port of ItemDatabaseHelper (item-file path): ingests a delimited item file
/// (ZIP or plain text) into a dynamically-schema'd `item_file_data` table and
/// records the schema + detected item/dept columns in `refresh_metadata`.
class ItemFileDb {
  static const tableItem = 'item_file_data';
  static const metaKeyItem = 'ITEM_FILE';
  static const _batchSize = 2000;

  /// Ingests raw download bytes (unzips when the payload is a ZIP).
  Future<int> ingestBytes(List<int> bytes) async {
    final text = _isZip(bytes) ? _unzipFirstEntry(bytes) : utf8.decode(bytes, allowMalformed: true);
    return ingestText(text);
  }

  /// Ingests delimited text: header row defines the schema; all rows inserted.
  Future<int> ingestText(String content) async {
    final lines = const LineSplitter()
        .convert(content)
        .where((l) => l.trim().isNotEmpty)
        .toList();
    if (lines.isEmpty) return 0;

    final delimiter = _detectDelimiter(lines.first);
    final columns = _splitLine(lines.first, delimiter);
    if (columns.isEmpty) return 0;

    final db = await AppDatabase.instance.database;
    final safeCols = columns.map(_sanitize).toList();
    final itemCol = _findItemColumn(columns);
    final deptCol = _findDeptColumn(columns);

    await db.execute('DROP TABLE IF EXISTS "$tableItem"');
    await db.execute(
        'CREATE TABLE "$tableItem" (${safeCols.map((c) => '"$c" TEXT').join(', ')})');

    final placeholders = List.filled(columns.length, '?').join(', ');
    final insertSql =
        'INSERT INTO "$tableItem" (${safeCols.map((c) => '"$c"').join(', ')}) VALUES ($placeholders)';

    var count = 0;
    for (var start = 1; start < lines.length; start += _batchSize) {
      final end = (start + _batchSize).clamp(0, lines.length);
      final batch = db.batch();
      for (var i = start; i < end; i++) {
        final values = _splitLine(lines[i], delimiter);
        final row = List<String>.generate(
            columns.length, (c) => c < values.length ? values[c] : '');
        batch.rawInsert(insertSql, row);
        count++;
      }
      await batch.commit(noResult: true);
    }

    // Indexes after bulk insert.
    if (itemCol != null) {
      await db.execute(
          'CREATE INDEX IF NOT EXISTS "idx_${tableItem}_item" ON "$tableItem" ("${_sanitize(itemCol)}")');
    }
    final upcCol = _resolve(columns, ['UPC', 'UPC_CODE', 'UPC_ITEM', 'BARCODE']);
    if (upcCol != null) {
      await db.execute(
          'CREATE INDEX IF NOT EXISTS "idx_${tableItem}_upc" ON "$tableItem" ("${_sanitize(upcCol)}")');
    }

    await db.insert(
      'refresh_metadata',
      {
        'tableKey': metaKeyItem,
        'columnSchemaJson': jsonEncode(columns),
        'itemColName': itemCol != null ? _sanitize(itemCol) : '',
        'deptColName': deptCol != null ? _sanitize(deptCol) : '',
        'recordCount': count,
        'lastUpdated': _timestamp(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return count;
  }

  /// Merges an inventory or delta-inventory file into the existing item table,
  /// updating rows matched on (ITEM_ID, DEPT_NAME) → (itemCol, deptCol) and
  /// adding any inventory columns not already present. Port of
  /// ItemDatabaseHelper.importInventoryDirectly. Returns rows updated.
  /// (No-op if the item file hasn't been ingested yet.)
  Future<int> ingestInventoryMerge(String content) async {
    final meta = await getMetadata();
    if (meta == null || meta.itemColName.isEmpty || meta.deptColName.isEmpty) {
      return 0;
    }
    final lines = const LineSplitter()
        .convert(content)
        .where((l) => l.trim().isNotEmpty)
        .toList();
    if (lines.isEmpty) return 0;

    final delimiter = _detectDelimiter(lines.first);
    final headers = _splitLine(lines.first, delimiter);
    final itemIdIdx = headers.indexWhere((h) => h.toUpperCase() == 'ITEM_ID');
    final deptNameIdx = headers.indexWhere((h) => h.toUpperCase() == 'DEPT_NAME');
    if (itemIdIdx < 0 || deptNameIdx < 0) return 0;

    final updateCols = <({int idx, String name})>[];
    for (var i = 0; i < headers.length; i++) {
      if (i == itemIdIdx || i == deptNameIdx) continue;
      updateCols.add((idx: i, name: _sanitize(headers[i])));
    }
    if (updateCols.isEmpty) return 0;

    final db = await AppDatabase.instance.database;

    // Add any inventory columns not yet present in the item table.
    final existing = (await db.rawQuery('PRAGMA table_info("$tableItem")'))
        .map((r) => (r['name'] ?? '').toString())
        .toSet();
    for (final c in updateCols) {
      if (!existing.contains(c.name)) {
        await db.execute('ALTER TABLE "$tableItem" ADD COLUMN "${c.name}" TEXT');
      }
    }

    final safeItem = meta.itemColName; // metadata stores sanitized names
    final safeDept = meta.deptColName;
    final setClause = updateCols.map((c) => '"${c.name}" = ?').join(', ');
    final sql =
        'UPDATE "$tableItem" SET $setClause WHERE "$safeItem" = ? AND "$safeDept" = ?';

    var updated = 0;
    for (var start = 1; start < lines.length; start += _batchSize) {
      final end = (start + _batchSize).clamp(0, lines.length);
      final batch = db.batch();
      for (var i = start; i < end; i++) {
        final fields = _splitLine(lines[i], delimiter);
        if (fields.length != headers.length) continue;
        final itemId = fields[itemIdIdx];
        final deptName = fields[deptNameIdx];
        if (itemId.isEmpty || deptName.isEmpty) continue;
        final args = <Object?>[
          for (final c in updateCols) c.idx < fields.length ? fields[c.idx] : '',
          itemId,
          deptName,
        ];
        batch.rawUpdate(sql, args);
        updated++;
      }
      await batch.commit(noResult: true);
    }
    return updated;
  }

  /// Inventory merge from raw bytes (unzips a ZIP payload first).
  Future<int> ingestInventoryMergeBytes(List<int> bytes) async {
    final text = _isZip(bytes)
        ? _unzipFirstEntry(bytes)
        : utf8.decode(bytes, allowMalformed: true);
    return ingestInventoryMerge(text);
  }

  Future<ItemFileMetadata?> getMetadata() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('refresh_metadata',
        where: 'tableKey = ?', whereArgs: [metaKeyItem], limit: 1);
    if (rows.isEmpty) return null;
    final m = rows.first;
    List<String> cols;
    try {
      cols = (jsonDecode((m['columnSchemaJson'] ?? '[]') as String) as List)
          .map((e) => e.toString())
          .toList();
    } catch (_) {
      cols = [];
    }
    return ItemFileMetadata(
      columns: cols.map(_sanitize).toList(),
      itemColName: (m['itemColName'] ?? '') as String,
      deptColName: (m['deptColName'] ?? '') as String,
      recordCount: (m['recordCount'] as int?) ?? 0,
      lastUpdated: (m['lastUpdated'] ?? '') as String,
    );
  }

  Future<bool> hasData() async => (await getMetadata())?.recordCount != null &&
      ((await getMetadata())!.recordCount) > 0;

  // ── Parsing helpers (ported) ────────────────────────────────────────────────
  bool _isZip(List<int> b) =>
      b.length >= 4 && b[0] == 0x50 && b[1] == 0x4B && b[2] == 0x03 && b[3] == 0x04;

  String _unzipFirstEntry(List<int> bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    for (final f in archive.files) {
      if (f.isFile) return utf8.decode(f.content as List<int>, allowMalformed: true);
    }
    return '';
  }

  String _detectDelimiter(String header) {
    const candidates = ['|', '\t', ','];
    var best = '|';
    var bestCount = -1;
    for (final d in candidates) {
      final n = header.split(d).length;
      if (n > bestCount) {
        bestCount = n;
        best = d;
      }
    }
    return best;
  }

  List<String> _splitLine(String line, String delimiter) => line
      .split(delimiter)
      .map((f) => f.trim().replaceAll(RegExp('^["\']|["\']\$'), '').trim())
      .toList();

  String _sanitize(String raw) {
    final s = raw.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_').replaceFirst(RegExp(r'^_+'), '');
    return s.isEmpty ? 'col' : s;
  }

  String? _findItemColumn(List<String> cols) =>
      _exact(cols, 'ITEM_CODE') ??
      _exact(cols, 'ITEM_NUM') ??
      _exact(cols, 'ITEM_NUMBER') ??
      _exact(cols, 'ITEMNO') ??
      _exact(cols, 'ITEM') ??
      _firstWhere(cols, (c) =>
          c.toUpperCase().contains('ITEM') &&
          (c.toUpperCase().contains('NBR') || c.toUpperCase().contains('NUM'))) ??
      _firstWhere(cols, (c) => c.toUpperCase().contains('ITEM'));

  String? _findDeptColumn(List<String> cols) =>
      _exact(cols, 'DEPT_NBR') ??
      _exact(cols, 'DEPT_NUM') ??
      _exact(cols, 'DEPT_NUMBER') ??
      _exact(cols, 'DEPT') ??
      _exact(cols, 'DEPARTMENT') ??
      _exact(cols, 'DEPT_NAME') ??
      _firstWhere(cols, (c) => c.toUpperCase().contains('DEPT'));

  String? _exact(List<String> cols, String name) {
    for (final c in cols) {
      if (c.toUpperCase() == name) return c;
    }
    return null;
  }

  String? _firstWhere(List<String> cols, bool Function(String) test) {
    for (final c in cols) {
      if (test(c)) return c;
    }
    return null;
  }

  String? _resolve(List<String> cols, List<String> candidates) {
    for (final cand in candidates) {
      final hit = _exact(cols, cand);
      if (hit != null) return hit;
    }
    return null;
  }

  String _timestamp() {
    final d = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour < 12 ? 'AM' : 'PM';
    return '${two(d.month)}/${two(d.day)}/${d.year} ${two(h12)}:${two(d.minute)} $ampm';
  }
}
