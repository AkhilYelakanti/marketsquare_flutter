import 'app_database.dart';
import 'item_file_db.dart';

/// A category selection entry: [code] is the value filtered on, [label] is the
/// "code - name" text shown in the list.
class CategoryPair {
  final String code;
  final String label;
  const CategoryPair(this.code, this.label);
}

/// Item catalog access (port of ItemCatalogRepository). Queries the dynamic
/// `item_file_data` table populated by Data Sync, resolving the real column
/// names from `refresh_metadata` at runtime.
///
/// Every returned row carries its raw CSV columns PLUS canonical alias keys
/// ([colItem], [colDesc], …) so the order-entry flow can read items by a fixed
/// key set regardless of the server's actual column names.
class ItemRepository {
  // Canonical alias keys the rest of the app reads.
  static const colItem = 'itemNumber';
  static const colDesc = 'description';
  static const colPack = 'pack';
  static const colUpc = 'upc';
  static const colDept = 'department';
  static const colAdEffective = 'adEffective';
  static const colAllowance = 'allowance';
  static const colCube = 'cube';
  static const colMults = 'itemCodeMults';

  final ItemFileDb _itemDb = ItemFileDb();

  /// Exact item-code / UPC match.
  Future<List<Map<String, String>>> queryByExactCode(String code) async {
    final meta = await _itemDb.getMetadata();
    if (meta == null || meta.columns.isEmpty) return [];
    final itemCol = meta.itemColName.isNotEmpty ? meta.itemColName : null;
    final upcCol = _resolve(meta.columns, const ['UPC', 'UPC_CODE', 'UPC_ITEM', 'BARCODE']);
    final parts = <String>[];
    final args = <Object>[];
    if (itemCol != null) {
      parts.add('"$itemCol" = ?');
      args.add(code);
    }
    if (upcCol != null) {
      parts.add('"$upcCol" = ?');
      args.add(code);
    }
    if (parts.isEmpty) return [];
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery(
        'SELECT * FROM "${ItemFileDb.tableItem}" WHERE ${parts.join(' OR ')} LIMIT 500',
        args);
    return rows.map((r) => _withAliases(r, meta)).toList();
  }

  /// Text search across item number + description + UPC (>= 3 chars).
  Future<List<Map<String, String>>> searchAll(String query,
      {int limit = 100, int offset = 0}) async {
    final q = query.trim();
    if (q.length < 3) return [];
    final meta = await _itemDb.getMetadata();
    if (meta == null || meta.columns.isEmpty) return [];
    final itemCol = meta.itemColName.isNotEmpty ? meta.itemColName : null;
    final descCol = _resolve(meta.columns,
        const ['DESCRIPTION', 'ITEM_DESCRIPTION', 'ITEM_DESC', 'LONG_DESCRIPTION', 'DESC']);
    final upcCol = _resolve(meta.columns, const ['UPC', 'UPC_CODE', 'UPC_ITEM', 'BARCODE']);

    final parts = <String>[];
    final args = <Object>[];
    final like = '%$q%';
    for (final c in [itemCol, descCol, upcCol]) {
      if (c != null) {
        parts.add('"$c" LIKE ?');
        args.add(like);
      }
    }
    if (parts.isEmpty) return [];
    final order = itemCol != null ? 'ORDER BY "$itemCol"' : '';
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery(
      'SELECT * FROM "${ItemFileDb.tableItem}" WHERE ${parts.join(' OR ')} $order LIMIT $limit OFFSET $offset',
      args,
    );
    return rows.map((r) => _withAliases(r, meta)).toList();
  }

  /// Distinct non-blank values of a column (department / category lists).
  Future<List<String>> distinctValues(String column) async {
    final db = await AppDatabase.instance.database;
    try {
      final rows = await db.rawQuery(
          'SELECT DISTINCT "$column" v FROM "${ItemFileDb.tableItem}" WHERE "$column" IS NOT NULL AND TRIM("$column") != \'\' ORDER BY "$column"');
      return rows.map((r) => (r['v'] ?? '').toString()).where((s) => s.isNotEmpty).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> hasData() async {
    final meta = await _itemDb.getMetadata();
    return meta != null && meta.recordCount > 0;
  }

  // ── Column kinds for filtering ────────────────────────────────────────────────
  static const _csCat = ['CS_CATEGORY', 'C_S_CATEGORY', 'CS_CAT'];
  static const _neilsonCat = ['NEILSON_CATEGORY', 'NIELSEN_CATEGORY', 'NEILSON_CAT'];
  static const _dealFlag = ['DEAL_FLAG', 'DEALS_FLAG', 'PROMO_FLAG', 'DEAL_INDICATOR'];
  static const _csDesc = [
    'CS_CATEGORY_DESCRIPTION', 'CS_CAT_DESC', 'CATEGORY_DESCRIPTION', 'CAT_DESCRIPTION'
  ];
  static const _neilsonName = [
    'NEILSON_NAME', 'NIELSEN_NAME', 'NEILSON_CATEGORY_NAME', 'NEILSON_DESC', 'NIELSEN_DESC'
  ];

  /// Distinct category (code, label) pairs where label = "code - name" (native
  /// `getDistinctCategoryPairs`). [kind] = 'CS' | 'NEILSON'. Falls back to the
  /// bare code when no description column exists.
  Future<List<CategoryPair>> distinctCategoryPairs(String kind) async {
    final meta = await _itemDb.getMetadata();
    if (meta == null) return [];
    final codeCol = _resolve(meta.columns, kind == 'NEILSON' ? _neilsonCat : _csCat);
    if (codeCol == null) return [];
    var descCol = _resolve(meta.columns, kind == 'NEILSON' ? _neilsonName : _csDesc);
    // Aggressive fallback for Neilson: any NEILSON_* column that isn't the code.
    if (descCol == null && kind == 'NEILSON') {
      for (final c in meta.columns) {
        if (c.toUpperCase().contains('NEILSON') &&
            c.toUpperCase() != codeCol.toUpperCase()) {
          descCol = c;
          break;
        }
      }
    }
    final db = await AppDatabase.instance.database;
    final sel = descCol != null ? '"$codeCol" c, "$descCol" d' : '"$codeCol" c';
    try {
      final rows = await db.rawQuery(
        'SELECT DISTINCT $sel FROM "${ItemFileDb.tableItem}" '
        'WHERE "$codeCol" IS NOT NULL AND TRIM("$codeCol") != \'\' ORDER BY "$codeCol"',
      );
      final out = <CategoryPair>[];
      final seen = <String>{};
      for (final r in rows) {
        final code = (r['c'] ?? '').toString().trim();
        if (code.isEmpty || !seen.add(code)) continue;
        final name = (r['d'] ?? '').toString().trim();
        out.add(CategoryPair(code, name.isEmpty ? code : '$code - $name'));
      }
      return out;
    } catch (_) {
      return [];
    }
  }

  /// Resolved department column name, or null.
  Future<String?> deptColumn() async {
    final meta = await _itemDb.getMetadata();
    if (meta == null) return null;
    return meta.deptColName.isNotEmpty ? meta.deptColName : null;
  }

  /// Resolved category column for a kind ('CS' | 'NEILSON').
  Future<String?> categoryColumn(String kind) async {
    final meta = await _itemDb.getMetadata();
    if (meta == null) return null;
    return _resolve(meta.columns, kind == 'NEILSON' ? _neilsonCat : _csCat);
  }

  /// Distinct non-blank values of a resolved column kind.
  Future<List<String>> distinctForKind(String kind) async {
    final meta = await _itemDb.getMetadata();
    if (meta == null) return [];
    final col = switch (kind) {
      'DEPT' => meta.deptColName.isNotEmpty ? meta.deptColName : null,
      'CS' => _resolve(meta.columns, _csCat),
      'NEILSON' => _resolve(meta.columns, _neilsonCat),
      _ => null,
    };
    if (col == null) return [];
    return distinctValues(col);
  }

  /// Filtered item query (department / category / deals / text).
  /// Extra columns to also match in a search (beyond item# + description).
  /// `extraSearchKinds` names candidate-sets resolved against the live schema;
  /// used by Search Images to also match IMAGE_ID / UPC_ITEM / UPC_CASE.
  static const _imageSearchCols = [
    ['IMAGE_ID', 'IMG_ID', 'IMAGEID', 'IMAGE_NAME'],
    ['UPC_ITEM', 'UPC_ITEM_CODE'],
    ['UPC_CASE', 'CASE_UPC'],
    ['UPC', 'UPC_CODE', 'BARCODE'],
  ];

  Future<List<Map<String, String>>> queryItems({
    String? dept,
    String? categoryKind, // 'CS' | 'NEILSON'
    String? category,
    bool dealsOnly = false,
    String? search,
    bool imageSearch = false,
    int limit = 500,
    int offset = 0,
  }) async {
    final meta = await _itemDb.getMetadata();
    if (meta == null || meta.columns.isEmpty) return [];
    final where = <String>[];
    final args = <Object>[];

    if (search != null && search.trim().isNotEmpty) {
      final like = '%${search.trim()}%';
      final itemCol = meta.itemColName.isNotEmpty ? meta.itemColName : null;
      final descCol = _resolve(meta.columns,
          const ['DESCRIPTION', 'ITEM_DESCRIPTION', 'ITEM_DESC', 'LONG_DESCRIPTION', 'DESC']);
      final cols = <String?>[itemCol, descCol];
      if (imageSearch) {
        for (final cand in _imageSearchCols) {
          cols.add(_resolve(meta.columns, cand));
        }
      }
      final parts = <String>[];
      final seen = <String>{};
      for (final c in cols) {
        if (c != null && seen.add(c)) {
          parts.add('"$c" LIKE ?');
          args.add(like);
        }
      }
      if (parts.isNotEmpty) where.add('(${parts.join(' OR ')})');
    }
    if (dept != null && dept.isNotEmpty && meta.deptColName.isNotEmpty) {
      where.add('"${meta.deptColName}" = ?');
      args.add(dept);
    }
    if (category != null && category.isNotEmpty && categoryKind != null) {
      final col = _resolve(meta.columns, categoryKind == 'NEILSON' ? _neilsonCat : _csCat);
      if (col != null) {
        where.add('"$col" = ?');
        args.add(category);
      }
    }
    if (dealsOnly) {
      final flag = _resolve(meta.columns, _dealFlag);
      if (flag != null) where.add('("$flag" = \'Y\' OR "$flag" = \'y\')');
    }
    final itemCol = meta.itemColName.isNotEmpty ? meta.itemColName : null;
    final order = itemCol != null ? 'ORDER BY "$itemCol"' : '';
    final ws = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery(
        'SELECT * FROM "${ItemFileDb.tableItem}" $ws $order LIMIT $limit OFFSET $offset', args);
    return rows.map((r) => _withAliases(r, meta)).toList();
  }

  Future<ItemFileMetadata?> metadata() => _itemDb.getMetadata();

  // ── Alias mapping ───────────────────────────────────────────────────────────
  Map<String, String> _withAliases(Map<String, Object?> row, ItemFileMetadata meta) {
    final out = <String, String>{};
    row.forEach((k, v) => out[k] = v?.toString() ?? '');
    void alias(String canonical, List<String> candidates, {String? preferred}) {
      final col = preferred ?? _resolve(meta.columns, candidates);
      if (col != null && out.containsKey(col)) out[canonical] = out[col]!;
    }

    alias(colItem, const [], preferred: meta.itemColName.isNotEmpty ? meta.itemColName : null);
    alias(colDesc, const ['DESCRIPTION', 'ITEM_DESCRIPTION', 'ITEM_DESC', 'LONG_DESCRIPTION', 'DESC']);
    alias(colPack, const ['PACK', 'PACK_SIZE', 'PACKSIZE']);
    alias(colUpc, const ['UPC', 'UPC_CODE', 'UPC_ITEM', 'BARCODE']);
    alias(colDept, const ['DEPT_NAME', 'DEPARTMENT', 'DEPT'],
        preferred: meta.deptColName.isNotEmpty ? meta.deptColName : null);
    alias(colAdEffective,
        const ['AD_EFFECTIVE', 'AD_EFFECTIVE_PRICE', 'AD_PRICE', 'EFFECTIVE_PRICE', 'PRICE']);
    alias(colAllowance, const ['CASECOST_ALLOWANCE', 'ALLOWANCE', 'CASE_ALLOWANCE']);
    alias(colCube, const ['ITEM_CUBE', 'CUBE']);
    alias(colMults, const ['ITEM_CODE_MULTS', 'ITEMCODEMULTS', 'MULTS']);
    return out;
  }

  String? _resolve(List<String> cols, List<String> candidates) {
    for (final cand in candidates) {
      for (final c in cols) {
        if (c.toUpperCase() == cand) return c;
      }
    }
    return null;
  }
}
