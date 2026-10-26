// Port of TileConfigData.kt + TileFormulaEvaluator.kt — LOV1 tile layout.

/// Grid bounds from a set of positions (value = row*100 + col).
class PositionBounds {
  final int minRow, maxRow, minCol, maxCol;
  const PositionBounds(this.minRow, this.maxRow, this.minCol, this.maxCol);
  int get rowSpan => maxRow - minRow + 1;
  int get colSpan => maxCol - minCol + 1;
}

/// One element of the tile grid (label / value / image / qty entry / calculated).
class TileElement {
  final String attributeName;
  final List<int> namePositions;
  final int nameColor;
  final String attributeValue;
  final List<int> valuePositions;
  final int valueColor;
  final int valueFontSize;
  final bool valueBold;
  final String valueType; // IMAGE | CALCULATED | HTML | ''
  final String attributeMath;
  final List<int> allPositions;

  const TileElement({
    this.attributeName = '',
    this.namePositions = const [],
    this.nameColor = 0xFF212F3C,
    this.attributeValue = '',
    this.valuePositions = const [],
    this.valueColor = 0xFF212F3C,
    this.valueFontSize = 12,
    this.valueBold = false,
    this.valueType = '',
    this.attributeMath = '',
    this.allPositions = const [],
  });

  bool get isImage => valueType.toUpperCase().startsWith('IMAGE');
  bool get isQtyEntry => attributeValue.toUpperCase() == 'QTY_ENTRY';
  bool get isCalculated => valueType.toUpperCase() == 'CALCULATED';

  /// Item-file column holding the image id for this IMAGE tile. An explicit
  /// `attributeValue` wins; otherwise IMAGE → IMAGE_ID, IMAGE2 → IMAGE_ID_2,
  /// IMAGE3 → IMAGE_ID_3 (native parity).
  String get imageIdColumn {
    final av = attributeValue.trim();
    if (av.isNotEmpty) return av;
    switch (valueType.toUpperCase()) {
      case 'IMAGE2':
        return 'IMAGE_ID_2';
      case 'IMAGE3':
        return 'IMAGE_ID_3';
      default:
        return 'IMAGE_ID';
    }
  }

  int get sortRow {
    final p = valuePositions.isNotEmpty ? valuePositions : allPositions;
    if (p.isEmpty) return 0;
    return p.map((e) => e ~/ 100).reduce((a, b) => a < b ? a : b);
  }

  int get sortCol {
    final p = valuePositions.isNotEmpty ? valuePositions : allPositions;
    if (p.isEmpty) return 0;
    return p.map((e) => e % 100).reduce((a, b) => a < b ? a : b);
  }
}

class OrderTileConfig {
  final int tileHeight;
  final int rowCount;
  final int columnCount;
  final List<TileElement> elements;
  const OrderTileConfig({
    this.tileHeight = 180,
    this.rowCount = 9,
    this.columnCount = 9,
    this.elements = const [],
  });
}

/// Parses one tileConfigMap entry (a JSON map) into an [OrderTileConfig].
OrderTileConfig parseTileConfig(Map<String, dynamic> obj) {
  int intOf(dynamic v, int d) => int.tryParse((v ?? '').toString()) ?? d;
  final elemsRaw = obj['orderTileElements'];
  final elements = <TileElement>[];
  if (elemsRaw is List) {
    for (final e in elemsRaw) {
      if (e is! Map) continue;
      final nameCss = (e['attributeNameCSS'] ?? '').toString();
      final valueCss = (e['attributeValueCSS'] ?? '').toString();
      elements.add(TileElement(
        attributeName: (e['attributeName'] ?? '').toString(),
        namePositions: _positions(e['attributeNamePosition']),
        nameColor: parseCssColor(nameCss),
        attributeValue: (e['attributeValue'] ?? '').toString(),
        valuePositions: _positions(e['attributeValuePosition']),
        valueColor: parseCssColor(valueCss),
        valueFontSize: parseCssFontSize(valueCss),
        valueBold: parseCssBold(valueCss),
        valueType: (e['attributeValueType'] ?? '').toString(),
        attributeMath: (e['attributeMath'] ?? '').toString(),
        allPositions: _positions(e['position']),
      ));
    }
  }
  return OrderTileConfig(
    tileHeight: intOf(obj['tileHeight'], 180),
    rowCount: intOf(obj['rowCount'], 9),
    columnCount: intOf(obj['columnCount'], 9),
    elements: elements,
  );
}

List<int> _positions(dynamic raw) {
  if (raw is! List) return [];
  final out = <int>[];
  for (final el in raw) {
    final s = el.toString();
    if (s.contains('-')) {
      final parts = s.split('-');
      final row = int.tryParse(parts.isNotEmpty ? parts[0] : '');
      final col = int.tryParse(parts.length > 1 ? parts[1] : '');
      if (row != null && col != null) out.add(row * 100 + col);
    } else {
      final n = int.tryParse(s);
      if (n != null) out.add((n ~/ 10) * 100 + (n % 10));
    }
  }
  return out;
}

int parseCssColor(String css) {
  final m = RegExp(r'color:\s*#([0-9a-fA-F]{3,8})', caseSensitive: false).firstMatch(css);
  if (m == null) return 0xFF212F3C;
  final hex = m.group(1)!;
  try {
    switch (hex.length) {
      case 3:
        final r = hex[0] * 2, g = hex[1] * 2, b = hex[2] * 2;
        return int.parse('FF$r$g$b', radix: 16);
      case 6:
        return int.parse('FF$hex', radix: 16);
      case 8:
        return int.parse(hex, radix: 16);
      default:
        return 0xFF212F3C;
    }
  } catch (_) {
    return 0xFF212F3C;
  }
}

int parseCssFontSize(String css) =>
    int.tryParse(RegExp(r'font-size:\s*(\d+)').firstMatch(css)?.group(1) ?? '') ?? 12;

bool parseCssBold(String css) =>
    css.toLowerCase().contains('font-weight') && css.toLowerCase().contains('bold');

/// Arithmetic formula evaluator for tile `attributeMath` (QTY_ENTRY + item cols).
/// Recursive-descent, standard precedence. Returns "" on error.
String evaluateTileFormula(
  String formula,
  Map<String, String> item,
  String qty,
  String Function(String key, Map<String, String> item) resolveField,
) {
  if (formula.trim().isEmpty) return '';
  try {
    final tokens = _tokenize(formula);
    final result = _FormulaParser(tokens, item, qty, resolveField).parseExpr();
    return result.toStringAsFixed(2);
  } catch (_) {
    return '';
  }
}

List<_Tok> _tokenize(String input) {
  final tokens = <_Tok>[];
  var i = 0;
  while (i < input.length) {
    final c = input[i];
    if (c.trim().isEmpty) {
      i++;
    } else if (RegExp(r'[0-9.]').hasMatch(c)) {
      final start = i;
      while (i < input.length && RegExp(r'[0-9.]').hasMatch(input[i])) {
        i++;
      }
      tokens.add(_Tok.num(double.tryParse(input.substring(start, i)) ?? 0));
    } else if (RegExp(r'[A-Za-z_]').hasMatch(c)) {
      final start = i;
      while (i < input.length && RegExp(r'[A-Za-z0-9_]').hasMatch(input[i])) {
        i++;
      }
      tokens.add(_Tok.id(input.substring(start, i)));
    } else if (c == '(') {
      tokens.add(const _Tok.lp());
      i++;
    } else if (c == ')') {
      tokens.add(const _Tok.rp());
      i++;
    } else if ('+-*/'.contains(c)) {
      tokens.add(_Tok.op(c));
      i++;
    } else {
      i++;
    }
  }
  return tokens;
}

class _Tok {
  final int kind; // 0 num, 1 id, 2 op, 3 lp, 4 rp
  final double num;
  final String s;
  const _Tok.num(this.num) : kind = 0, s = '';
  const _Tok.id(this.s) : kind = 1, num = 0;
  const _Tok.op(this.s) : kind = 2, num = 0;
  const _Tok.lp() : kind = 3, num = 0, s = '';
  const _Tok.rp() : kind = 4, num = 0, s = '';
}

class _FormulaParser {
  final List<_Tok> tokens;
  final Map<String, String> item;
  final String qty;
  final String Function(String, Map<String, String>) resolveField;
  int pos = 0;
  _FormulaParser(this.tokens, this.item, this.qty, this.resolveField);

  _Tok? _peek() => pos < tokens.length ? tokens[pos] : null;
  _Tok _consume() => tokens[pos++];

  double parseExpr() {
    var result = _parseTerm();
    while (_peek()?.kind == 2 && (_peek()!.s == '+' || _peek()!.s == '-')) {
      final op = _consume().s;
      final rhs = _parseTerm();
      result = op == '+' ? result + rhs : result - rhs;
    }
    return result;
  }

  double _parseTerm() {
    var result = _parseFactor();
    while (_peek()?.kind == 2 && (_peek()!.s == '*' || _peek()!.s == '/')) {
      final op = _consume().s;
      final rhs = _parseFactor();
      result = op == '*' ? result * rhs : (rhs == 0 ? 0 : result / rhs);
    }
    return result;
  }

  double _parseFactor() {
    final t = _peek();
    if (t == null) return 0;
    if (t.kind == 0) {
      _consume();
      return t.num;
    }
    if (t.kind == 1) {
      _consume();
      // The entered quantity is referenced as QTY_ENTRY / QUANTITY / QTY.
      const qtyTokens = {'QTY_ENTRY', 'QUANTITY', 'QTY'};
      if (qtyTokens.contains(t.s.toUpperCase())) return double.tryParse(qty) ?? 0;
      return double.tryParse(resolveField(t.s, item)) ?? 0;
    }
    if (t.kind == 3) {
      _consume();
      final r = parseExpr();
      if (_peek()?.kind == 4) _consume();
      return r;
    }
    return 0;
  }
}
