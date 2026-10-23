import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'alert_pipeline.dart';
import 'field_resolver.dart';
import 'order_entry_controller.dart';
import 'tile_config.dart';

/// Config-driven item tile (port of ItemTileCard). Renders the LOV1 tile layout
/// when a config is supplied (elements laid out by grid row/col with CSS
/// styling, calculated formulas, and a qty-entry stepper); otherwise a sensible
/// default layout. Applies the alert watermark/background when present.
class ItemTileCard extends StatelessWidget {
  final Map<String, String> item;
  final OrderTileConfig? config;
  final String qty;
  final ValueChanged<String>? onQty;
  final VoidCallback? onTap;
  final String? watermark;
  final String? backgroundHex;

  const ItemTileCard({
    super.key,
    required this.item,
    this.config,
    this.qty = '0',
    this.onQty,
    this.onTap,
    this.watermark,
    this.backgroundHex,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    Color? bg;
    if (backgroundHex != null && backgroundHex!.trim().isNotEmpty) {
      bg = Color(parseCssColor('color:${backgroundHex!}'));
    }
    final body = (config != null && config!.elements.isNotEmpty)
        ? _configured(context, primary)
        : _default(context, primary);

    return Card(
      color: bg ?? Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Padding(padding: const EdgeInsets.all(10), child: body),
            if (watermark != null && watermark!.trim().isNotEmpty)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  color: Colors.red.withValues(alpha: 0.85),
                  child: Text(watermark!.split('\n').first,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _qtyStepper(Color primary) {
    final n = int.tryParse(qty) ?? 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: onQty == null ? null : () => onQty!('${n - 1 < 0 ? 0 : n - 1}'),
          icon: Icon(Icons.remove_circle_outline, color: primary),
        ),
        Text('$n', style: const TextStyle(fontWeight: FontWeight.bold)),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: onQty == null ? null : () => onQty!('${n + 1}'),
          icon: Icon(Icons.add_circle_outline, color: primary),
        ),
      ],
    );
  }

  Widget _default(BuildContext context, Color primary) {
    final number = resolveItemField('ITEM_NUMBER', item);
    final desc = resolveItemField('ITEM_DESCRIPTION', item);
    final pack = resolveItemField('PACK_SIZE', item);
    final price = resolveItemField('AD_EFFECTIVE', item);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(desc.isEmpty ? number : desc,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              Text(
                  '# $number'
                  '${pack.isNotEmpty ? '  •  $pack' : ''}'
                  '${price.isNotEmpty ? '  •  \$$price' : ''}',
                  style: const TextStyle(fontSize: 11, color: Colors.black54)),
            ],
          ),
        ),
        _qtyStepper(primary),
      ],
    );
  }

  /// Faithful grid render: each element is positioned on the config's
  /// rowCount×columnCount grid (positions are 1-indexed `row*100+col`), so the
  /// label and value cells land exactly where the LOV tile defines them
  /// (image block left, cost label/value columns, qty box, etc.).
  Widget _configured(BuildContext context, Color primary) {
    final cols = config!.columnCount > 0 ? config!.columnCount : 9;
    final rows = config!.rowCount > 0 ? config!.rowCount : 9;
    final h = (config!.tileHeight > 0 ? config!.tileHeight : 180).toDouble();

    // Normalise to the config's own origin (positions may be 1-indexed like the
    // real LOV "11".."99", or 0-indexed like older/demo configs).
    var minRow = 1 << 30, minCol = 1 << 30;
    for (final e in config!.elements) {
      for (final p in [...e.namePositions, ...e.valuePositions, ...e.allPositions]) {
        minRow = math.min(minRow, p ~/ 100);
        minCol = math.min(minCol, p % 100);
      }
    }
    if (minRow == 1 << 30) minRow = 0;
    if (minCol == 1 << 30) minCol = 0;

    return LayoutBuilder(
      builder: (ctx, cns) {
        final cellW = cns.maxWidth / cols;
        final cellH = h / rows;
        Rect? rectOf(List<int> pos) {
          if (pos.isEmpty) return null;
          final rs = pos.map((e) => e ~/ 100);
          final cs = pos.map((e) => e % 100);
          final r0 = rs.reduce(math.min), r1 = rs.reduce(math.max);
          final c0 = cs.reduce(math.min), c1 = cs.reduce(math.max);
          return Rect.fromLTWH((c0 - minCol) * cellW, (r0 - minRow) * cellH,
              (c1 - c0 + 1) * cellW, (r1 - r0 + 1) * cellH);
        }

        final children = <Widget>[];
        for (final e in config!.elements) {
          // Label (attributeName) at its own cells.
          final label = e.attributeName.trim();
          if (label.isNotEmpty) {
            final nb = rectOf(
                e.namePositions.isNotEmpty ? e.namePositions : e.valuePositions);
            if (nb != null) {
              children.add(Positioned.fromRect(
                  rect: nb,
                  child: _gridText(label, Color(e.nameColor), 10, false)));
            }
          }
          // Value / image / qty entry.
          final vb = rectOf(
              e.valuePositions.isNotEmpty ? e.valuePositions : e.allPositions);
          if (vb == null) continue;
          Widget content;
          if (e.isImage) {
            content = _imageCell();
          } else if (e.isQtyEntry) {
            content = _qtyBox(primary);
          } else {
            final v = e.isCalculated
                ? evaluateTileFormula(e.attributeMath, item, qty, resolveItemField)
                : resolveItemField(e.attributeValue, item);
            content = _gridText(v, Color(e.valueColor),
                e.valueFontSize.toDouble().clamp(9.0, 15.0), e.valueBold);
          }
          children.add(Positioned.fromRect(rect: vb, child: content));
        }

        return SizedBox(
            width: cns.maxWidth, height: h, child: Stack(children: children));
      },
    );
  }

  Widget _gridText(String text, Color color, double size, bool bold) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Text(text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: color,
                fontSize: size,
                height: 1.05,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  Widget _imageCell() => Padding(
        padding: const EdgeInsets.all(3),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F2),
            borderRadius: BorderRadius.circular(3),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.image, size: 24, color: Colors.black26),
        ),
      );

  /// Qty box (native parity): tap = +1, long-press = −1.
  Widget _qtyBox(Color primary) {
    final n = int.tryParse(qty) ?? 0;
    return Padding(
      padding: const EdgeInsets.all(3),
      child: InkWell(
        onTap: onQty == null ? null : () => onQty!('${n + 1}'),
        onLongPress:
            onQty == null ? null : () => onQty!('${n - 1 < 0 ? 0 : n - 1}'),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black38),
            borderRadius: BorderRadius.circular(2),
          ),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('$n',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}

/// Wraps an item in an [ItemTileCard] bound to the order controller: reflects
/// the current line qty and commits through the alert pipeline.
class OrderItemTile extends ConsumerWidget {
  final Map<String, String> item;
  const OrderItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(orderEntryControllerProvider);
    final ctrl = ref.read(orderEntryControllerProvider.notifier);
    final line = st.lineFor(item);
    return ItemTileCard(
      item: item,
      config: st.config.getOrderTileConfig(st.selectedOrderType),
      qty: line?.qty ?? '0',
      watermark: line?.alertWatermarkText,
      backgroundHex: line?.alertBackgroundHex,
      onQty: (v) => ctrl.commitItem(item, v),
    );
  }
}

/// Renders the shared alert dialog whenever a pending alert is set. Drop one
/// into each order-flow screen (port of OrderAlertHost).
class OrderAlertHost extends ConsumerStatefulWidget {
  const OrderAlertHost({super.key});

  @override
  ConsumerState<OrderAlertHost> createState() => _OrderAlertHostState();
}

class _OrderAlertHostState extends ConsumerState<OrderAlertHost> {
  bool _showing = false;

  @override
  Widget build(BuildContext context) {
    ref.listen(orderEntryControllerProvider.select((s) => s.pendingAlert),
        (_, alert) {
      if (alert != null && !_showing) _show(alert);
    });
    return const SizedBox.shrink();
  }

  Future<void> _show(PendingItemStatusAlert alert) async {
    _showing = true;
    final ctrl = ref.read(orderEntryControllerProvider.notifier);
    final e = alert.evaluation;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dctx) => AlertDialog(
        title: Text(e.config.itemAlertHeaderText.isEmpty ? 'ALERT' : e.config.itemAlertHeaderText),
        content: Text(e.popupText.isEmpty ? e.watermarkText : e.popupText),
        actions: [
          if (e.showTwoButtons)
            TextButton(
              onPressed: () {
                Navigator.pop(dctx);
                ctrl.skipAlert();
              },
              child: Text(e.config.itemAlertButton2Text.isEmpty
                  ? 'CANCEL'
                  : e.config.itemAlertButton2Text),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(dctx);
              ctrl.acceptAlert();
            },
            child: Text(e.config.itemAlertButton1Text.isEmpty
                ? 'OK'
                : e.config.itemAlertButton1Text),
          ),
        ],
      ),
    );
    _showing = false;
  }
}
