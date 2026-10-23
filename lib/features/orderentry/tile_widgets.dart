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

  Widget _configured(BuildContext context, Color primary) {
    // Native tile layout = image block on the left, text fields (grouped by grid
    // row, ordered by column) in the middle, qty stepper on the right.
    TileElement? imageEl;
    TileElement? qtyEl;
    final textEls = <TileElement>[];
    for (final e in config!.elements) {
      if (e.isImage) {
        imageEl ??= e;
      } else if (e.isQtyEntry) {
        qtyEl ??= e;
      } else {
        textEls.add(e);
      }
    }
    textEls.sort((a, b) {
      final r = a.sortRow.compareTo(b.sortRow);
      return r != 0 ? r : a.sortCol.compareTo(b.sortCol);
    });
    final byRow = <int, List<TileElement>>{};
    for (final e in textEls) {
      (byRow[e.sortRow] ??= []).add(e);
    }
    final rows = byRow.keys.toList()..sort();

    final textColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final e in byRow[r]!) Flexible(child: _cell(e, primary)),
              ],
            ),
          ),
      ],
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (imageEl != null) ...[
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.image, size: 30, color: Colors.black26),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(child: textColumn),
        const SizedBox(width: 8),
        _qtyStepper(primary),
      ],
    );
  }

  Widget _cell(TileElement e, Color primary) {
    if (e.isQtyEntry) return _qtyStepper(primary);
    final value = e.isCalculated
        ? evaluateTileFormula(e.attributeMath, item, qty, resolveItemField)
        : (e.isImage ? '' : resolveItemField(e.attributeValue, item));
    final label = e.attributeName.trim();
    final style = TextStyle(
      color: Color(e.valueColor),
      fontSize: e.valueFontSize.toDouble(),
      fontWeight: e.valueBold ? FontWeight.bold : FontWeight.normal,
    );
    if (e.isImage) {
      return const Padding(
        padding: EdgeInsets.all(2),
        child: Icon(Icons.image, size: 28, color: Colors.black26),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label.isNotEmpty)
            Text(label,
                style: TextStyle(fontSize: 10, color: Color(e.nameColor))),
          Text(value, style: style),
        ],
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
