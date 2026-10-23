import 'package:flutter_test/flutter_test.dart';

import 'package:marketsquare/data/push/push_navigator.dart';
import 'package:marketsquare/data/session/session_providers.dart';
import 'package:marketsquare/features/orderentry/alert_pipeline.dart';
import 'package:marketsquare/features/orderentry/order_config.dart';
import 'package:marketsquare/features/orderentry/tile_config.dart';
import 'package:marketsquare/router/app_routes.dart';

void main() {
  test('brand color hex parsing matches native parseBrandColor', () {
    expect(parseBrandColor('#DB2031')?.toARGB32(), 0xFFDB2031);
    expect(parseBrandColor('DB2031')?.toARGB32(), 0xFFDB2031);
    expect(parseBrandColor('FFDB2031')?.toARGB32(), 0xFFDB2031);
    expect(parseBrandColor(''), isNull);
    expect(parseBrandColor(null), isNull);
    expect(parseBrandColor('nothex'), isNull);
  });

  test('push data maps to the right deep-link route', () {
    expect(PushNavigator.routeFor('HOME', {}), Routes.dashboard);
    expect(PushNavigator.routeFor('REVIEW_ORDERS', {}), Routes.reviewOrders);
    expect(
      PushNavigator.routeFor('ORDER_APPROVALS', {'confirmId': 'X1'}),
      '${Routes.approvalOrderDetail}?confirmId=X1',
    );
    expect(
      PushNavigator.routeFor('INVOICES', {'invoiceNumber': '9'}),
      '${Routes.invoiceDetail}?invoiceNumber=9',
    );
    expect(PushNavigator.routeFor('UNKNOWN', {}), isNull);
  });

  test('LOV1 config parses lists, gates, and control buttons', () {
    const raw = '''
    {
      "requestTypes": ["ITEM_ORDER", "AD_ORDER"],
      "storeDeptPartition": ["GROCERY", "DAIRY"],
      "storeNumbers": ["18316-Highland Park", "22451-Downtown"],
      "crReasonCodes": ["03 - Not Ordered"],
      "restrictDepartment": "Y",
      "orderMinimumCheckRequestTypes": {"ITEM_ORDER": "Y", "AD_ORDER": "N"},
      "addRecommendedItemsToOrder": "Y",
      "addRecommendedItemstoOrderSequence": "1",
      "recommendedItemsCheckRequestTypes": {"ITEM_ORDER": "Y"},
      "orderApprovalView": "Y",
      "enableOrderApproveRoleButton": "Y",
      "orderControlButtons": {"ITEM_ORDER": {"SAVED": "Y", "DEALS": "N"}},
      "orderTotals": [{"key": "EST_VALUE", "label": "Est", "prefix": "\$"}],
      "email": "help@cswg.com"
    }''';
    final cfg = OrderConfig.fromLov1Json(raw);
    expect(cfg.requestTypes, ['ITEM_ORDER', 'AD_ORDER']);
    expect(cfg.partitions, ['GROCERY', 'DAIRY']);
    expect(cfg.customers.first.storeId, '18316');
    expect(cfg.crReasonCodes, ['03 - Not Ordered']);
    expect(cfg.deptRestricted, isTrue);
    expect(cfg.isOrderMinimumCheckEnabled('ITEM_ORDER'), isTrue);
    expect(cfg.isOrderMinimumCheckEnabled('AD_ORDER'), isFalse);
    expect(cfg.isRecommendedItemsCheckEnabled('ITEM_ORDER'), isTrue);
    expect(cfg.isApprovalSubmit, isTrue);
    // Y/N map control-button format: only SAVED (Y) survives.
    expect(cfg.controlButtons.map((b) => b.key), contains('SAVED'));
    expect(cfg.controlButtons.map((b) => b.key), isNot(contains('DEALS')));
    expect(cfg.totalFields.single.key, 'EST_VALUE');
  });

  test('empty LOV1 falls back to defaults', () {
    final cfg = OrderConfig.fromLov1Json(null);
    expect(cfg.requestTypes, OrderConfig.defaultRequestTypes);
    expect(cfg.isApprovalSubmit, isFalse);
    expect(cfg.isOrderMinimumCheckEnabled('ITEM_ORDER'), isFalse);
  });

  test('alert pipeline: status-code popup, qty max, and no-alert', () {
    const statusCfgs = [
      ItemStatusAlertConfig(
        itemStatus: 'DS',
        itemAlertNeeded: 'Y',
        itemWatermarkAlertText: 'DISCONTINUED',
        itemAlertButton1Text: 'Order Sub',
        itemAlertButton2Text: 'Cancel',
      ),
    ];
    const alertCfgs = [
      AlertMessagesConfig(
          alertType: 'MAX_QTY_ALERT',
          alertNeeded: 'Y',
          alertText: 'Exceeds max of',
          button1Text: 'OK'),
    ];

    // DS status → popup evaluation with watermark + alternate id.
    final ds = evaluateAlert(
      item: {'STATUS_CODE': 'DS', 'ALTERNATE_ITEM_ID': '999'},
      qty: '1',
      firstAdd: true,
      statusConfigs: statusCfgs,
      alertConfigs: alertCfgs,
    );
    expect(ds, isNotNull);
    expect(ds!.shouldShowPopup, isTrue);
    expect(ds.isDiscontinued, isTrue);
    expect(ds.alternateItemId, '999');

    // Qty over the max → MAX_QTY popup.
    final max = evaluateAlert(
      item: {'ITEM_NUMBER': '100'},
      qty: '50',
      firstAdd: true,
      statusConfigs: statusCfgs,
      alertConfigs: alertCfgs,
      allowedMaxQuantity: 10,
    );
    expect(max, isNotNull);
    expect(max!.popupText, contains('10'));

    // Clean item, qty in bounds → no alert.
    final none = evaluateAlert(
      item: {'ITEM_NUMBER': '100'},
      qty: '2',
      firstAdd: true,
      statusConfigs: statusCfgs,
      alertConfigs: alertCfgs,
      allowedMaxQuantity: 10,
    );
    expect(none, isNull);
  });

  test('tile formula evaluates AD_EFFECTIVE * QTY_ENTRY', () {
    final v = evaluateTileFormula(
      'AD_EFFECTIVE*QTY_ENTRY',
      {'adEffective': '6.49'},
      '2',
      (k, item) => item[k == 'AD_EFFECTIVE' ? 'adEffective' : k] ?? '',
    );
    expect(v, '12.98');
  });
}
