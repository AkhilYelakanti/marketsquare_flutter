import 'dart:convert';

import '../../data/models/order_models.dart';
import 'alert_pipeline.dart';
import 'tile_config.dart';

/// Normalises "AD ORDER" / "ad-order" → "AD_ORDER".
String normalizeTypeKey(String raw) =>
    raw.trim().toUpperCase().replaceAll(' ', '_').replaceAll('-', '_');

/// Maps a LOV `orderTotals` key (totalItem/totalCube/…) to a value key + prefix.
({String key, String prefix}) _mapTotalKey(String raw) {
  switch (raw.trim()) {
    case 'totalItem':
      return (key: 'ITEM_QTY', prefix: '');
    case 'totalCases':
      return (key: 'CASE_QTY', prefix: '');
    case 'totalCube':
      return (key: 'CUBE', prefix: '');
    case 'totalEst':
      return (key: 'EST_VALUE', prefix: '\$');
    case 'totalAllowance':
      return (key: 'ALLOWANCE', prefix: '\$');
    default:
      return (key: raw.trim().toUpperCase(), prefix: '');
  }
}

final _dynamicSpec = RegExp(r'^(data\d+|date\d+)_(.+)$', caseSensitive: false);

/// Parses "data1_STORE_ACCOUNT" → (DATA1, "STORE ACCOUNT", dropdown|text|date).
({String key, String label, String type})? parseDynamicFieldSpec(String raw) {
  final m = _dynamicSpec.firstMatch(raw);
  if (m == null) return null;
  final prefix = m.group(1)!.toLowerCase();
  final suffix = m.group(2)!.replaceAll('_', ' ').trim();
  final type = prefix.startsWith('date')
      ? 'date'
      : (prefix == 'data1' ? 'dropdown' : 'text');
  return (key: prefix.toUpperCase(), label: suffix, type: type);
}

/// Port of SessionManager.stringToFormFieldConfig — maps a plain form-field
/// string from `formFieldsInOrdering` to a FormFieldConfig.
FormFieldConfig stringToFormFieldConfig(String raw) {
  final upper = raw.trim().toUpperCase();
  FormFieldConfig f(String k, String l, String t, [String src = '']) =>
      FormFieldConfig(fieldKey: k, label: l, type: t, source: src);
  switch (upper) {
    case 'STORE PARTITION':
    case 'PARTITION':
      return f('PARTITION', 'Store Partition', 'dropdown', 'storeDeptPartition');
    case 'PO':
      return const FormFieldConfig(
          fieldKey: 'PO', label: 'PO', type: 'text', placeholder: 'Required');
    case 'COMMENTS':
      return const FormFieldConfig(
          fieldKey: 'COMMENTS', label: 'Comments', type: 'textarea', placeholder: 'Optional');
    case 'DELIVERY DATE':
    case 'DELIVERY_DATE':
      return f('DELIVERY_DATE', 'Delivery Date', 'date');
    case 'AD DATE':
    case 'AD_DATE':
      return f('AD_DATE', 'Ad Date', 'date');
    case 'AD ID':
    case 'AD_ID':
      return f('AD_ID', 'AD Id', 'text');
    case 'DATA1':
      return f('DATA1', 'Data1', 'dropdown', 'data1DropDownValues');
    case 'DATA2':
      return f('DATA2', 'Data2', 'text');
    case 'DATA3':
      return f('DATA3', 'Data3', 'text');
    case 'DATE1':
      return f('DATE1', 'Date1', 'date');
    case 'DATE2':
      return f('DATE2', 'Date2', 'date');
    case 'CR_REASON_CODE':
    case 'REASON CODE':
    case 'REASON CODES':
    case 'REASON_CODE':
    case 'REASON_CODES':
      return f('CR_REASON_CODE', 'Reason Codes', 'dropdown', 'crReasonCodes');
    case 'CR_TYPE':
    case 'CREDIT TYPE':
    case 'CREDIT_TYPE':
      return f('CR_TYPE', 'Credit Type', 'dropdown', 'crTypes');
    case 'INVOICE#':
    case 'INVOICE #':
    case 'INVOICE_NUMBER':
    case 'CR_INVOICE_NUMBER':
      return f('INVOICE#', 'Invoice#', 'text');
  }
  if (RegExp(r'^DATE\d+$').hasMatch(upper)) return f(upper, raw.trim(), 'date');
  if (RegExp(r'^DATA1$').hasMatch(upper)) {
    return f('DATA1', raw.trim(), 'dropdown', 'data1DropDownValues');
  }
  if (RegExp(r'^DATA\d+$').hasMatch(upper)) return f(upper, raw.trim(), 'text');
  final key = upper.replaceAll(' ', '_').replaceAll('-', '_');
  return f(key, raw.trim(), 'text');
}

/// Order-entry configuration from the stored LOV1 JSON (full faithful parse of
/// the SessionManager LOV1 getters), with the ViewModel's DEFAULT_* fallbacks.
class OrderConfig {
  final List<CustomerEntry> customers;
  final List<String> requestTypes;
  final List<String> partitions;
  final List<FormFieldConfig> formFields;
  final Map<String, List<String>> mandatoryFieldsMap;
  final Map<String, List<String>> optionalFieldsMap;
  final List<OrderControlButton> controlButtons;
  final List<OrderTotalField> totalFields;
  /// Totals keyed by request type (real LOV shape); falls back to [totalFields].
  final Map<String, List<OrderTotalField>> totalsByType;
  /// Fallback tile config (`defaultTileConfig`) for the catalog / unmapped types.
  final OrderTileConfig? defaultTile;
  final List<String> data1LovValues;
  final List<String> crReasonCodes;
  final List<String> crTypes;
  final bool deptRestricted;
  final bool displayAddTagToItem;
  final bool displayDepartmentBreakup;
  // Gates
  final Set<String> orderMinCheckTypes;
  final Set<String> recommendedCheckTypes;
  final bool addRecommendedEnabled;
  final bool orderApprovalView;
  final bool approveRoleButton;
  // Extra lists
  final List<String> deptList;
  final List<String> storeCategoryList;
  final List<String> storeInvoices;
  // Alerts + tiles
  final List<ItemStatusAlertConfig> itemStatusAlertConfigs;
  final List<AlertMessagesConfig> alertMessagesConfigs;
  final int? allowedMaxQuantity;
  final Map<String, OrderTileConfig> orderTileConfigs;

  const OrderConfig({
    required this.customers,
    required this.requestTypes,
    required this.partitions,
    required this.formFields,
    required this.mandatoryFieldsMap,
    required this.optionalFieldsMap,
    required this.controlButtons,
    required this.totalFields,
    this.totalsByType = const {},
    this.defaultTile,
    required this.data1LovValues,
    required this.crReasonCodes,
    required this.crTypes,
    required this.deptRestricted,
    required this.displayAddTagToItem,
    required this.displayDepartmentBreakup,
    this.orderMinCheckTypes = const {},
    this.recommendedCheckTypes = const {},
    this.addRecommendedEnabled = false,
    this.orderApprovalView = false,
    this.approveRoleButton = false,
    this.deptList = const [],
    this.storeCategoryList = const [],
    this.storeInvoices = const [],
    this.itemStatusAlertConfigs = const [],
    this.alertMessagesConfigs = const [],
    this.allowedMaxQuantity,
    this.orderTileConfigs = const {},
  });

  /// Tile config for a request type, falling back to the default tile config.
  OrderTileConfig? getOrderTileConfig(String? requestType) {
    if (requestType == null) return defaultTile;
    return orderTileConfigs[normalizeTypeKey(requestType)] ?? defaultTile;
  }

  /// Totals row for a request type (real LOV is keyed by type; else defaults).
  List<OrderTotalField> totalFieldsForType(String? requestType) {
    if (requestType != null) {
      final t = totalsByType[normalizeTypeKey(requestType)];
      if (t != null && t.isNotEmpty) return t;
    }
    return totalFields.isNotEmpty ? totalFields : defaultTotalFields;
  }

  static const defaultRequestTypes = [
    'ITEM_ORDER', 'AD_ORDER', 'PRICE_CHANGE', 'TAG_ORDER', 'TOBACCO', 'TPR',
  ];

  static const List<FormFieldConfig> defaultFormFields = [
    FormFieldConfig(
        fieldKey: 'PARTITION',
        label: 'Store Partition',
        type: 'dropdown',
        source: 'storeDeptPartition'),
    FormFieldConfig(fieldKey: 'PO', label: 'PO', type: 'text', placeholder: 'Required'),
    FormFieldConfig(
        fieldKey: 'COMMENTS', label: 'Comments', type: 'text', placeholder: 'Optional'),
    FormFieldConfig(
        fieldKey: 'DELIVERY_DATE',
        label: 'Delivery Date',
        type: 'text',
        placeholder: 'MM/DD/YYYY'),
  ];

  static const List<OrderTotalField> defaultTotalFields = [
    OrderTotalField(key: 'ITEM_QTY', label: 'Item Qty'),
    OrderTotalField(key: 'CASE_QTY', label: 'Case Qty'),
    OrderTotalField(key: 'EST_VALUE', label: 'Est Value', prefix: '\$'),
    OrderTotalField(key: 'ALLOWANCE', label: 'Allowance', prefix: '\$'),
  ];

  static const Map<String, List<String>> defaultMandatory = {
    'ITEM_ORDER': ['PO'],
    'AD_ORDER': ['PO'],
    'PRICE_CHANGE': ['PO'],
    'TAG_ORDER': ['PO'],
    'TOBACCO': ['PO'],
    'TPR': ['PO'],
  };

  factory OrderConfig.defaults() => const OrderConfig(
        customers: [],
        requestTypes: defaultRequestTypes,
        partitions: ['All Depts'],
        formFields: defaultFormFields,
        mandatoryFieldsMap: defaultMandatory,
        optionalFieldsMap: {},
        controlButtons: [],
        totalFields: defaultTotalFields,
        data1LovValues: [],
        crReasonCodes: [],
        crTypes: [],
        deptRestricted: false,
        displayAddTagToItem: false,
        displayDepartmentBreakup: false,
      );

  static List<String> _strList(Map<String, dynamic> root, List<String> keys) {
    for (final k in keys) {
      final v = root[k];
      if (v is List) {
        return v
            .map((e) => e.toString().trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }
    }
    return [];
  }

  static bool _flag(dynamic v) {
    final s = (v ?? '').toString().trim().toUpperCase();
    return s == 'Y' || s == 'TRUE';
  }

  /// Full LOV1 parse (faithful to SessionManager). Falls back to defaults per key.
  factory OrderConfig.fromLov1Json(String? rawJson) {
    if (rawJson == null || rawJson.trim().isEmpty) return OrderConfig.defaults();
    Map<String, dynamic> root;
    try {
      root = jsonDecode(rawJson) as Map<String, dynamic>;
    } catch (_) {
      return OrderConfig.defaults();
    }

    // Customers
    final customers = <CustomerEntry>[];
    final rawCust = root['storeNumbers'] ?? root['customerList'];
    if (rawCust is List) {
      for (final el in rawCust) {
        if (el is String) {
          final s = el.trim();
          if (s.isEmpty) continue;
          customers.add(s.contains('-')
              ? CustomerEntry(
                  rawData: s,
                  storeId: s.substring(0, s.indexOf('-')).trim(),
                  storeName: s.substring(s.indexOf('-') + 1).trim())
              : CustomerEntry(rawData: s, storeId: s, storeName: ''));
        } else if (el is Map) {
          final id = (el['storeId'] ?? '').toString().trim();
          if (id.isEmpty) continue;
          final name = (el['storeName'] ?? '').toString().trim();
          customers.add(CustomerEntry(storeId: id, storeName: name));
        }
      }
    }

    final requestTypes = _strList(root, ['requestTypes']).isNotEmpty
        ? _strList(root, ['requestTypes']).map((s) => s.replaceAll(',', '').trim()).toList()
        : defaultRequestTypes;

    final partitions = _strList(root, ['storeDeptPartition', 'partitionList']).isNotEmpty
        ? _strList(root, ['storeDeptPartition', 'partitionList'])
        : ['All Depts'];

    // Form fields
    final formFields = <FormFieldConfig>[];
    final rawFields = root['formFieldsInOrdering'] ?? root['formFeildsInOrdering'];
    if (rawFields is List) {
      for (final el in rawFields) {
        if (el is String && el.trim().isNotEmpty) {
          formFields.add(stringToFormFieldConfig(el.trim()));
        } else if (el is Map) {
          final key = (el['fieldKey'] ?? '').toString().trim();
          if (key.isEmpty) continue;
          formFields.add(FormFieldConfig(
            fieldKey: key,
            label: (el['label'] ?? key).toString(),
            type: (el['type'] ?? 'text').toString(),
            placeholder: (el['placeholder'] ?? '').toString(),
            source: (el['source'] ?? '').toString(),
          ));
        }
      }
    }

    // Mandatory / optional field maps (keyed by request type)
    Map<String, List<String>> fieldMap(String key) {
      final m = root[key];
      if (m is! Map) return {};
      final out = <String, List<String>>{};
      m.forEach((k, v) {
        if (v is List) {
          out[normalizeTypeKey(k.toString())] =
              v.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
        }
      });
      return out;
    }

    final mandatory = fieldMap('requestAttributesMandatory');
    final optional = fieldMap('requestAttributesOptional');

    // Control buttons (map or array)
    final controlButtons = _parseControlButtons(root['orderControlButtons']);

    // Totals. Real LOV keys this by request type:
    //   orderTotals: { ITEM_ORDER: { totalItem: "Total Item Qty", ... }, ... }
    // (older/demo configs used a flat list of {key,label,prefix}).
    final totalsByType = <String, List<OrderTotalField>>{};
    final totals = <OrderTotalField>[];
    final rawTotals = root['orderTotals'];
    if (rawTotals is Map) {
      rawTotals.forEach((type, m) {
        if (m is! Map) return;
        final list = <OrderTotalField>[];
        m.forEach((k, label) {
          final mapped = _mapTotalKey(k.toString());
          list.add(OrderTotalField(
              key: mapped.key, label: label.toString(), prefix: mapped.prefix));
        });
        if (list.isNotEmpty) totalsByType[normalizeTypeKey(type.toString())] = list;
      });
    } else if (rawTotals is List) {
      for (final el in rawTotals) {
        if (el is Map) {
          final key = (el['key'] ?? '').toString().trim();
          if (key.isEmpty) continue;
          totals.add(OrderTotalField(
            key: key,
            label: (el['label'] ?? key).toString(),
            prefix: (el['prefix'] ?? '').toString(),
          ));
        }
      }
    }

    // Gate maps
    Set<String> yMap(String key) {
      final m = root[key];
      if (m is! Map) return {};
      final out = <String>{};
      m.forEach((k, v) {
        if (_flag(v)) out.add(normalizeTypeKey(k.toString()));
      });
      return out;
    }

    final addRecommended = _flag(root['addRecommendedItemsToOrder']) &&
        (root['addRecommendedItemstoOrderSequence'] ?? '').toString().trim() == '1';

    // Alert configs
    final statusAlerts = <ItemStatusAlertConfig>[];
    final rawStatus = root['itemStatusAlertMessagesConfig'];
    if (rawStatus is List) {
      for (final e in rawStatus) {
        if (e is Map && (e['itemStatus'] ?? '').toString().isNotEmpty) {
          statusAlerts.add(ItemStatusAlertConfig.fromJson(e));
        }
      }
    }
    final alertMsgs = <AlertMessagesConfig>[];
    final rawAlerts = root['alertMessagesConfig'];
    if (rawAlerts is List) {
      for (final e in rawAlerts) {
        if (e is Map && (e['alertType'] ?? '').toString().isNotEmpty) {
          alertMsgs.add(AlertMessagesConfig.fromJson(e));
        }
      }
    }
    final maxQty = int.tryParse((root['allowedMaxQuantity'] ?? '').toString().trim());

    // Tile configs: tileByRequestType[type] = configName → tileConfigMap[configName],
    // with `defaultTileConfig` naming the fallback (used by the item catalog and
    // any request type without an explicit mapping).
    final tiles = <String, OrderTileConfig>{};
    final byType = root['tileByRequestType'];
    final configMap = root['tileConfigMap'];
    OrderTileConfig? defaultTile;
    if (configMap is Map) {
      final defName = (root['defaultTileConfig'] ?? '').toString().trim();
      final defCfg = defName.isNotEmpty ? configMap[defName] : null;
      if (defCfg is Map) {
        defaultTile = parseTileConfig(Map<String, dynamic>.from(defCfg));
      }
      if (byType is Map) {
        byType.forEach((type, cfgName) {
          final cfg = configMap[cfgName.toString()];
          if (cfg is Map) {
            tiles[normalizeTypeKey(type.toString())] =
                parseTileConfig(Map<String, dynamic>.from(cfg));
          }
        });
      }
    }

    return OrderConfig(
      customers: customers,
      requestTypes: requestTypes,
      partitions: partitions,
      formFields: formFields.isNotEmpty ? formFields : defaultFormFields,
      mandatoryFieldsMap: mandatory.isNotEmpty ? mandatory : defaultMandatory,
      optionalFieldsMap: optional,
      controlButtons: controlButtons,
      totalFields: totals.isNotEmpty ? totals : defaultTotalFields,
      totalsByType: totalsByType,
      defaultTile: defaultTile,
      data1LovValues: _strList(root, ['data1DropDownValues']),
      crReasonCodes: _strList(root, ['crReasonCodes']),
      crTypes: _strList(root, ['crTypes']),
      deptRestricted: (root['restrictDepartment'] ?? '').toString().trim().toUpperCase() == 'Y',
      displayAddTagToItem: _flag(root['displayAddTagToItem']),
      displayDepartmentBreakup: _flag(root['displayDepartmentBreakup']),
      orderMinCheckTypes: yMap('orderMinimumCheckRequestTypes'),
      recommendedCheckTypes: yMap('recommendedItemsCheckRequestTypes'),
      addRecommendedEnabled: addRecommended,
      orderApprovalView: _flag(root['orderApprovalView']),
      approveRoleButton: _flag(root['enableOrderApproveRoleButton']),
      deptList: _strList(root, ['departments', 'departmentList']),
      storeCategoryList: _strList(root, ['storeCategoryList']),
      storeInvoices: _strList(root, ['storeInvoices']),
      itemStatusAlertConfigs: statusAlerts,
      alertMessagesConfigs: alertMsgs,
      allowedMaxQuantity: (maxQty != null && maxQty > 0) ? maxQty : null,
      orderTileConfigs: tiles,
    );
  }

  static List<OrderControlButton> _parseControlButtons(dynamic element) {
    const iconHints = {
      'PARTITION': 'tune',
      'DEALS': 'local_offer',
      'LINKED': 'link',
      'SAVED': 'bookmark',
      'SCAN': 'scan',
      'NEW': 'add',
      'SEND': 'send',
      'SUBMIT': 'send',
      'SEARCH': 'search',
    };
    final result = <OrderControlButton>[];
    if (element is Map) {
      element.forEach((typeName, inner) {
        final type = typeName.toString().toUpperCase();
        if (inner is List) {
          for (final el in inner) {
            if (el is! Map) continue;
            final key = (el['key'] ?? '').toString().trim();
            if (key.isEmpty) continue;
            result.add(OrderControlButton(
              key: key,
              label: (el['label'] ?? key).toString(),
              icon: (el['icon'] ?? '').toString(),
              requestTypes: [type],
            ));
          }
        } else if (inner is Map) {
          inner.forEach((btnKey, flag) {
            if (!_flag(flag)) return;
            final k = btnKey.toString().toUpperCase();
            result.add(OrderControlButton(
              key: k,
              label: k,
              icon: iconHints[k] ?? k.toLowerCase(),
              requestTypes: [type],
            ));
          });
        }
      });
    } else if (element is List) {
      for (final el in element) {
        if (el is! Map) continue;
        final key = (el['key'] ?? '').toString().trim();
        if (key.isEmpty) continue;
        final rt = el['requestTypes'] ?? el['requestType'];
        final types = <String>[];
        if (rt is List) {
          types.addAll(rt.map((e) => e.toString().trim().toUpperCase()).where((s) => s.isNotEmpty));
        } else if (rt is String && rt.trim().isNotEmpty) {
          types.add(rt.trim().toUpperCase());
        }
        result.add(OrderControlButton(
          key: key,
          label: (el['label'] ?? key).toString(),
          icon: (el['icon'] ?? '').toString(),
          requestTypes: types,
        ));
      }
    }
    return result;
  }

  // ── Gate toggles (now LOV1-driven) ────────────────────────────────────────────
  bool isOrderMinimumCheckEnabled(String requestType) =>
      orderMinCheckTypes.contains(normalizeTypeKey(requestType));
  bool isRecommendedItemsCheckEnabled(String requestType) =>
      addRecommendedEnabled && recommendedCheckTypes.contains(normalizeTypeKey(requestType));
  bool get isApprovalSubmit => orderApprovalView && approveRoleButton;

  /// Port of getFieldsForOrderType.
  List<FieldRow> fieldsForOrderType(String? requestType) {
    if (requestType == null) return [];
    final normType = normalizeTypeKey(requestType);
    final mandatoryRaw = mandatoryFieldsMap[normType] ?? const [];
    final optionalRaw = optionalFieldsMap[normType] ?? const [];
    final hasConfig = mandatoryRaw.isNotEmpty || optionalRaw.isNotEmpty;

    String keyOf(String raw) =>
        parseDynamicFieldSpec(raw)?.key ?? stringToFormFieldConfig(raw).fieldKey.toUpperCase();
    final mandatoryKeys = mandatoryRaw.map(keyOf).toSet();
    final optionalKeys = optionalRaw.map(keyOf).toSet();

    const baseKeys = {'PARTITION', 'PO', 'COMMENTS'};
    final visibleKeys = hasConfig
        ? ({...baseKeys, ...mandatoryKeys, ...optionalKeys})
        : ({...baseKeys, 'DELIVERY_DATE'});

    bool isMandatory(String fKey) {
      if (fKey == 'PO') return true;
      if (deptRestricted && fKey == 'PARTITION') return true;
      if (!hasConfig && visibleKeys.contains(fKey)) return fKey != 'COMMENTS';
      return mandatoryKeys.contains(fKey);
    }

    final seen = <String>{};
    final result = <FieldRow>[];
    for (final config in formFields) {
      final fKey = config.fieldKey.toUpperCase();
      if (!visibleKeys.contains(fKey) || seen.contains(fKey)) continue;
      seen.add(fKey);
      result.add(FieldRow(config, isMandatory(fKey)));
    }
    for (final raw in [...mandatoryRaw, ...optionalRaw]) {
      final spec = parseDynamicFieldSpec(raw);
      if (spec != null) {
        if (seen.contains(spec.key)) continue;
        seen.add(spec.key);
        result.add(FieldRow(
          FormFieldConfig(
            fieldKey: spec.key,
            label: spec.label,
            type: spec.type,
            source: spec.type == 'dropdown' ? 'data1DropDownValues' : '',
          ),
          isMandatory(spec.key),
        ));
      } else {
        final config = stringToFormFieldConfig(raw);
        final fKey = config.fieldKey.toUpperCase();
        if (seen.contains(fKey)) continue;
        seen.add(fKey);
        result.add(FieldRow(config, isMandatory(fKey)));
      }
    }
    return result;
  }

  /// Mandatory keys for validation (port of validateHeader rules).
  Set<String> mandatoryKeysForType(String? requestType) {
    if (requestType == null) return {};
    final normType = normalizeTypeKey(requestType);
    final mandatoryRaw = mandatoryFieldsMap[normType] ?? const [];
    final optionalRaw = optionalFieldsMap[normType] ?? const [];
    final hasConfig = mandatoryRaw.isNotEmpty || optionalRaw.isNotEmpty;
    final keys = <String>{'PO'};
    if (deptRestricted) keys.add('PARTITION');
    if (!hasConfig) {
      keys.addAll(['PARTITION', 'COMMENTS', 'DELIVERY_DATE']);
    } else {
      for (final raw in mandatoryRaw) {
        keys.add(parseDynamicFieldSpec(raw)?.key ??
            stringToFormFieldConfig(raw).fieldKey.toUpperCase());
      }
    }
    return keys;
  }
}
