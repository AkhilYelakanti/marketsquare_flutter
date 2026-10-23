import '../../data/db/item_repository.dart';

/// Resolves a tile/formula logical field key to an item value. Maps well-known
/// logical keys to the canonical alias columns the catalog produces, then falls
/// back to a raw column match (exact, then case-insensitive).
String resolveItemField(String key, Map<String, String> item) {
  final k = key.trim().toUpperCase();
  final canonical = <String, String>{
    'ITEM_DESCRIPTION': ItemRepository.colDesc,
    'DESCRIPTION': ItemRepository.colDesc,
    'ITEM_DESC': ItemRepository.colDesc,
    'ITEM_NUMBER': ItemRepository.colItem,
    'ITEM_CODE': ItemRepository.colItem,
    'ITEM': ItemRepository.colItem,
    'PACK_SIZE': ItemRepository.colPack,
    'PACK': ItemRepository.colPack,
    'UPC': ItemRepository.colUpc,
    'DEPT': ItemRepository.colDept,
    'DEPARTMENT': ItemRepository.colDept,
    'DEPT_NAME': ItemRepository.colDept,
    'AD_EFFECTIVE': ItemRepository.colAdEffective,
    'AD_PRICE': ItemRepository.colAdEffective,
    'PRICE': ItemRepository.colAdEffective,
    'ALLOWANCE': ItemRepository.colAllowance,
    'CASECOST_ALLOWANCE': ItemRepository.colAllowance,
    'ITEM_CUBE': ItemRepository.colCube,
    'CUBE': ItemRepository.colCube,
  }[k];
  if (canonical != null && (item[canonical] ?? '').isNotEmpty) return item[canonical]!;
  // Raw exact.
  if (item.containsKey(key)) return item[key] ?? '';
  // Case-insensitive raw.
  for (final e in item.entries) {
    if (e.key.toUpperCase() == k) return e.value;
  }
  return '';
}

/// Finds the actual column name in an item row matching any candidate (CI).
String? resolveColumnName(Map<String, String> item, List<String> candidates) {
  for (final cand in candidates) {
    final cu = cand.toUpperCase();
    for (final key in item.keys) {
      if (key.toUpperCase() == cu) return key;
    }
  }
  return null;
}
