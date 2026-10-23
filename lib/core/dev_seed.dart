import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/item_file_db.dart';
import '../data/db/message.dart';
import '../data/db/message_dao.dart';
import '../data/session/session_providers.dart';
import '../features/orderentry/order_entry_controller.dart';

/// Demo LOV1 config used by the debug-only seed. Exercises alerts (DS popup, SI
/// silent watermark, low max-qty), control buttons, totals, and a tile config.
const _demoLov1 = '''
{
  "storeNumbers": ["18316-Highland Park Manchester"],
  "requestTypes": ["ITEM_ORDER", "AD_ORDER", "CREDIT_REQUEST"],
  "storeDeptPartition": ["GROCERY", "DAIRY", "FROZEN", "BAKERY", "HBC", "DELI"],
  "departments": ["GROCERY", "DAIRY", "FROZEN", "BAKERY", "HBC", "DELI"],
  "restrictDepartment": "N",
  "allowedMaxQuantity": "5",
  "email": "support@cswg.com",
  "phoneNumber": "1-800-555-0100",
  "messagesSubject": ["IMPORTANT", "RECALL", "GENERAL"],
  "orderControlButtons": {"ITEM_ORDER": {"SAVED": "Y", "DEALS": "Y", "SCAN": "Y"}},
  "orderTotals": [
    {"key": "ITEM_QTY", "label": "Items"},
    {"key": "CASE_QTY", "label": "Cases"},
    {"key": "EST_VALUE", "label": "Est", "prefix": "\$"}
  ],
  "alertMessagesConfig": [
    {"alertType": "MAX_QTY_ALERT", "alertNeeded": "Y",
     "alertText": "Quantity exceeds the maximum of", "button1Text": "OK", "alertHeaderText": "MAX QTY"},
    {"alertType": "MESSAGE_IMPORTANT", "alertNeeded": "Y",
     "alertText": "You have an unread IMPORTANT message. Please review it now.",
     "button1Text": "READ", "button2Text": "LATER", "alertHeaderText": "IMPORTANT MESSAGE"}
  ],
  "itemStatusAlertMessagesConfig": [
    {"itemStatus": "DS", "itemAlertNeeded": "Y", "itemWatermarkAlertText": "DISCONTINUED",
     "itemWatermarkBackgroundcolor": "#FFEBEE", "itemAlertButton1Text": "Order Sub",
     "itemAlertButton2Text": "Cancel", "itemDisplayButtonFlag": "Y", "itemAlertHeaderText": "DISCONTINUED ITEM"},
    {"itemStatus": "SI", "itemAlertNeeded": "N", "itemWatermarkAlertText": "SEASONAL",
     "itemWatermarkBackgroundcolor": "#FFF8E1"}
  ],
  "tileByRequestType": {"ITEM_ORDER": "t1"},
  "tileConfigMap": {
    "t1": {
      "tileHeight": "150", "rowCount": "3", "columnCount": "3",
      "orderTileElements": [
        {"attributeValue": "ITEM_DESCRIPTION", "attributeValuePosition": ["0-0"],
         "attributeValueCSS": "color:#212f3c;font-size: 15px;font-weight: bold;"},
        {"attributeName": "Pack", "attributeNamePosition": ["1-0"],
         "attributeValue": "PACK_SIZE", "attributeValuePosition": ["1-0"],
         "attributeValueCSS": "color:#555;font-size: 12px;"},
        {"attributeName": "Price", "attributeNamePosition": ["1-1"],
         "attributeValue": "AD_EFFECTIVE", "attributeValuePosition": ["1-1"],
         "attributeValueCSS": "color:#2e7d32;font-size: 13px;"},
        {"attributeName": "Est", "attributeNamePosition": ["1-2"],
         "attributeValue": "EST", "attributeValueType": "CALCULATED",
         "attributeMath": "AD_EFFECTIVE*QTY_ENTRY", "attributeValuePosition": ["1-2"],
         "attributeValueCSS": "color:#2e7d32;font-size: 13px;font-weight: bold;"},
        {"attributeValue": "QTY_ENTRY", "attributeValuePosition": ["2-0"]}
      ]
    }
  }
}
''';

/// Debug-only: seeds a fake session + LOV1 config + sample catalog so the order
/// flow, tiles, and alerts can be exercised without a backend. NOT shipped.
Future<void> seedDemo(WidgetRef ref) async {
  final sm = ref.read(sessionManagerProvider);
  await sm.saveSessionData('18316', 'DEMO', '1', 'demo');
  await sm.saveAuthToken('dev-token');
  await sm.saveServiceId('dev');
  await sm.saveBrandingData(backgroundColor: '#DB2031');
  await sm.saveLov1ConfigJson(_demoLov1);

  final content = await rootBundle.loadString('assets/sample_items.psv');
  await ItemFileDb().ingestText(content);

  // Seed a few inbound messages (incl. an unread IMPORTANT → mandatory alert).
  final now = DateTime.now();
  await MessageDao().insertNew([
    MessageRow(
      messageKey: 'demo-imp-1',
      notificationType: 'IMPORTANT',
      messageBody: 'Recall: check lot codes on item 100701 before ordering.',
      contactName: 'HQ Operations',
      lastCommunicationDate: '10/22/2026',
      receivedAt: now.millisecondsSinceEpoch,
    ),
    MessageRow(
      messageKey: 'demo-gen-1',
      notificationType: 'GENERAL',
      messageBody: 'Weekly ad resets Thursday. New deals available.',
      contactName: 'Marketing',
      lastCommunicationDate: '10/21/2026',
      receivedAt: now.millisecondsSinceEpoch - 86400000,
    ),
  ]);

  ref.read(orderEntryControllerProvider.notifier).loadConfig();
}
