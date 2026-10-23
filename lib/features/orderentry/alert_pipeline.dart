import 'field_resolver.dart';

// Port of the order-entry alert pipeline (AlertPipeline / QtyAlertEvaluator /
// ItemStatusAlertEvaluator + configs). Status-code alerts + qty max/min bounds.

/// LOV1 `alertMessagesConfig` entry (qty + inventory alerts).
class AlertMessagesConfig {
  final String alertType;
  final String alertNeeded;
  final String alertText;
  final String color;
  final String button1Text;
  final String button2Text;
  final String alertHeaderText;
  const AlertMessagesConfig({
    this.alertType = '',
    this.alertNeeded = 'N',
    this.alertText = '',
    this.color = '#ffffff',
    this.button1Text = '',
    this.button2Text = '',
    this.alertHeaderText = '',
  });
  factory AlertMessagesConfig.fromJson(Map j) => AlertMessagesConfig(
        alertType: (j['alertType'] ?? '').toString(),
        alertNeeded: (j['alertNeeded'] ?? 'N').toString(),
        alertText: (j['alertText'] ?? '').toString(),
        color: (j['color'] ?? '#ffffff').toString(),
        button1Text: (j['button1Text'] ?? '').toString(),
        button2Text: (j['button2Text'] ?? '').toString(),
        alertHeaderText: (j['alertHeaderText'] ?? '').toString(),
      );
}

/// LOV1 `itemStatusAlertMessagesConfig` entry (per item status).
class ItemStatusAlertConfig {
  final String itemStatus;
  final String itemAlertNeeded;
  final String itemWatermarkAlertText;
  final String itemWatermarkBackgroundcolor;
  final String itemAlertButton1Text;
  final String itemAlertButton2Text;
  final String itemDisplayButtonFlag;
  final String itemAlertHeaderText;
  const ItemStatusAlertConfig({
    this.itemStatus = '',
    this.itemAlertNeeded = 'N',
    this.itemWatermarkAlertText = '',
    this.itemWatermarkBackgroundcolor = '',
    this.itemAlertButton1Text = '',
    this.itemAlertButton2Text = 'OK',
    this.itemDisplayButtonFlag = 'Y',
    this.itemAlertHeaderText = 'ALERT',
  });
  factory ItemStatusAlertConfig.fromJson(Map j) => ItemStatusAlertConfig(
        itemStatus: (j['itemStatus'] ?? '').toString(),
        itemAlertNeeded: (j['itemAlertNeeded'] ?? 'N').toString(),
        itemWatermarkAlertText: (j['itemWatermarkAlertText'] ?? '').toString(),
        itemWatermarkBackgroundcolor:
            (j['itemWatermarkBackgroundcolor'] ?? '').toString(),
        itemAlertButton1Text: (j['itemAlertButton1Text'] ?? '').toString(),
        itemAlertButton2Text: (j['itemAlertButton2Text'] ?? 'OK').toString(),
        itemDisplayButtonFlag: (j['itemDisplayButtonFlag'] ?? 'Y').toString(),
        itemAlertHeaderText: (j['itemAlertHeaderText'] ?? 'ALERT').toString(),
      );
}

/// Outcome of evaluating an item against the alert configs.
class ItemStatusAlertEvaluation {
  final ItemStatusAlertConfig config;
  final String popupText;
  final String watermarkText;
  final String backgroundHex;
  final String alternateItemId;
  const ItemStatusAlertEvaluation({
    required this.config,
    this.popupText = '',
    this.watermarkText = '',
    this.backgroundHex = '',
    this.alternateItemId = '',
  });

  bool get shouldShowPopup => config.itemAlertNeeded.toUpperCase() == 'Y';
  bool get showTwoButtons => config.itemDisplayButtonFlag.toUpperCase() == 'Y';
  bool get isDiscontinued => config.itemStatus.toUpperCase() == 'DS';
}

/// A pending alert awaiting the user's accept/skip choice.
class PendingItemStatusAlert {
  final Map<String, String> item;
  final String qty;
  final String newPrice;
  final ItemStatusAlertEvaluation evaluation;
  const PendingItemStatusAlert({
    required this.item,
    required this.qty,
    this.newPrice = '',
    required this.evaluation,
  });
}

/// Pure pipeline. Status-code alert on first add, then qty max/min bounds.
/// Returns null → commit directly.
ItemStatusAlertEvaluation? evaluateAlert({
  required Map<String, String> item,
  required String qty,
  required bool firstAdd,
  required List<ItemStatusAlertConfig> statusConfigs,
  required List<AlertMessagesConfig> alertConfigs,
  int? allowedMaxQuantity,
}) {
  final trim = qty.trim();
  if (trim.isEmpty || trim == '0') return null;

  // ── Status-code alert (first add only) ───────────────────────────────────
  ItemStatusAlertEvaluation? statusMatch;
  if (firstAdd && statusConfigs.isNotEmpty) {
    final statusCol = resolveColumnName(item, ['STATUS_CODE', 'ITEM_STATUS', 'STATUS']);
    final code = statusCol != null ? (item[statusCol] ?? '').trim() : '';
    if (code.isNotEmpty) {
      final cfg = statusConfigs.firstWhere(
        (c) => c.itemStatus.toUpperCase() == code.toUpperCase(),
        orElse: () => const ItemStatusAlertConfig(itemStatus: '__none__'),
      );
      if (cfg.itemStatus != '__none__') {
        final msgCol = resolveColumnName(item, ['STATUS_MSG', 'STATUS_MESSAGE']);
        final statusMsg = msgCol != null ? (item[msgCol] ?? '').trim() : '';
        final isDs = cfg.itemStatus.toUpperCase() == 'DS';
        final altCol = resolveColumnName(item, ['ALTERNATE_ITEM_ID', 'ALT_ITEM_ID', 'SUB_ITEM']);
        final altId = (isDs && altCol != null) ? (item[altCol] ?? '').trim() : '';
        statusMatch = ItemStatusAlertEvaluation(
          config: cfg,
          popupText: [
            if (cfg.itemWatermarkAlertText.trim().isNotEmpty) cfg.itemWatermarkAlertText.trim(),
            if (statusMsg.isNotEmpty) statusMsg,
            if (altId.isNotEmpty) 'Sub Item: $altId',
          ].join('\n'),
          watermarkText: cfg.itemWatermarkAlertText,
          backgroundHex: cfg.itemWatermarkBackgroundcolor,
          alternateItemId: altId,
        );
      }
    }
  }
  if (statusMatch != null && statusMatch.shouldShowPopup) return statusMatch;

  // ── Qty bounds ─────────────────────────────────────────────────────────────
  final parsedQty = int.tryParse(trim);
  if (parsedQty != null && parsedQty > 0) {
    // MAX
    if (allowedMaxQuantity != null && allowedMaxQuantity > 0 && parsedQty > allowedMaxQuantity) {
      final cfg = alertConfigs.firstWhere(
        (c) => c.alertType.toUpperCase() == 'MAX_QTY_ALERT',
        orElse: () => const AlertMessagesConfig(alertType: '__none__'),
      );
      if (cfg.alertType != '__none__') {
        return _fromAlertMessages(cfg, '${cfg.alertText.trimRight()} $allowedMaxQuantity');
      }
    }
    // MIN (first add only)
    if (firstAdd) {
      final limitCol = resolveColumnName(item, ['ITEM_QTY_LIMITS', 'ITEM_QTY_LIMIT', 'MIN_QTY']);
      final minLimit =
          limitCol != null ? int.tryParse((item[limitCol] ?? '').trim()) : null;
      if (minLimit != null && minLimit > 0 && parsedQty < minLimit) {
        final cfg = alertConfigs.firstWhere(
          (c) => c.alertType.toUpperCase() == 'MIN_QTY_ALERT',
          orElse: () => const AlertMessagesConfig(alertType: '__none__'),
        );
        if (cfg.alertType != '__none__') {
          return _fromAlertMessages(cfg, '${cfg.alertText.trimRight()} $minLimit');
        }
      }
    }
  }

  return statusMatch; // silent status alert (watermark/bg) or null
}

ItemStatusAlertEvaluation _fromAlertMessages(AlertMessagesConfig cfg, String popup) {
  final twoButtons = cfg.button1Text.isNotEmpty;
  return ItemStatusAlertEvaluation(
    config: ItemStatusAlertConfig(
      itemStatus: cfg.alertType,
      itemAlertNeeded: cfg.alertNeeded,
      itemWatermarkAlertText: cfg.alertText,
      itemWatermarkBackgroundcolor: cfg.color,
      itemAlertButton1Text: cfg.button1Text,
      itemAlertButton2Text: cfg.button2Text,
      itemDisplayButtonFlag: twoButtons ? 'Y' : 'N',
      itemAlertHeaderText: cfg.alertHeaderText.isEmpty ? 'ALERT' : cfg.alertHeaderText,
    ),
    // Qty alerts don't watermark the tile (native parity).
    popupText: popup,
    watermarkText: '',
    backgroundHex: '',
  );
}
