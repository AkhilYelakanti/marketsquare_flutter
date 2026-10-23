import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/item_repository.dart';
import '../../data/db/pending_order.dart';
import '../../data/db/pending_order_dao.dart';
import '../../data/models/order_models.dart';
import '../../data/session/session_providers.dart';
import 'alert_pipeline.dart';
import 'order_config.dart';

/// Order-line sort modes for the QTY / CHARGE sort toggles.
enum OrderSort { none, qtyAsc, qtyDesc, chargeAsc, chargeDesc }

/// Immutable state for the whole Order Entry flow (port of OrderEntryViewModel
/// state). Shared across every order screen via [orderEntryControllerProvider].
class OrderEntryState {
  final OrderConfig config;
  final bool configLoaded;
  final CustomerEntry? selectedCustomer;
  final String? selectedOrderType;
  final Map<String, String> headerValues;
  final List<OrderLine> orderLines;
  final List<Map<String, String>> multsCandidates;
  final String multsScannedCode;
  final int? editingOrderId;
  final PendingItemStatusAlert? pendingAlert;
  final OrderSort activeSort;
  /// Per-item editable tile fields (FILL_EDITABLE), keyed `"itemCode|FIELD"`.
  final Map<String, String> customFields;

  OrderEntryState({
    required this.config,
    this.configLoaded = false,
    this.selectedCustomer,
    this.selectedOrderType,
    this.headerValues = const {},
    this.orderLines = const [],
    this.multsCandidates = const [],
    this.multsScannedCode = '',
    this.editingOrderId,
    this.pendingAlert,
    this.activeSort = OrderSort.none,
    this.customFields = const {},
  });

  String customField(Map<String, String> item, String key) =>
      customFields['${item[ItemRepository.colItem] ?? ''}|$key'] ?? '';

  OrderEntryState copyWith({
    OrderConfig? config,
    bool? configLoaded,
    CustomerEntry? selectedCustomer,
    String? selectedOrderType,
    Map<String, String>? headerValues,
    List<OrderLine>? orderLines,
    List<Map<String, String>>? multsCandidates,
    String? multsScannedCode,
    int? editingOrderId,
    PendingItemStatusAlert? pendingAlert,
    OrderSort? activeSort,
    Map<String, String>? customFields,
    bool clearCustomer = false,
    bool clearOrderType = false,
    bool clearEditingId = false,
    bool clearAlert = false,
  }) =>
      OrderEntryState(
        config: config ?? this.config,
        configLoaded: configLoaded ?? this.configLoaded,
        selectedCustomer:
            clearCustomer ? null : (selectedCustomer ?? this.selectedCustomer),
        selectedOrderType:
            clearOrderType ? null : (selectedOrderType ?? this.selectedOrderType),
        headerValues: headerValues ?? this.headerValues,
        orderLines: orderLines ?? this.orderLines,
        multsCandidates: multsCandidates ?? this.multsCandidates,
        multsScannedCode: multsScannedCode ?? this.multsScannedCode,
        editingOrderId:
            clearEditingId ? null : (editingOrderId ?? this.editingOrderId),
        pendingAlert: clearAlert ? null : (pendingAlert ?? this.pendingAlert),
        activeSort: activeSort ?? this.activeSort,
        customFields: customFields ?? this.customFields,
      );

  /// Order lines in display order: sorted by the active QTY/CHARGE sort, else
  /// newest-first (native default).
  List<OrderLine> get sortedLines {
    final list = [...orderLines];
    double chargeOf(OrderLine l) {
      final q = double.tryParse(l.qty) ?? 0;
      final p = double.tryParse(l.item[ItemRepository.colAdEffective] ?? '') ?? 0;
      return q * p;
    }

    int qtyOf(OrderLine l) => int.tryParse(l.qty) ?? 0;
    switch (activeSort) {
      case OrderSort.qtyAsc:
        list.sort((a, b) => qtyOf(a).compareTo(qtyOf(b)));
      case OrderSort.qtyDesc:
        list.sort((a, b) => qtyOf(b).compareTo(qtyOf(a)));
      case OrderSort.chargeAsc:
        list.sort((a, b) => chargeOf(a).compareTo(chargeOf(b)));
      case OrderSort.chargeDesc:
        list.sort((a, b) => chargeOf(b).compareTo(chargeOf(a)));
      case OrderSort.none:
        return list.reversed.toList();
    }
    return list;
  }

  // ── Convenience accessors (port of VM getters) ──────────────────────────────
  String get selectedPartition =>
      headerValues['PARTITION'] ??
      (config.partitions.isNotEmpty ? config.partitions.first : 'DEFAULT-ALL');
  String get poNumber => headerValues['PO'] ?? '';
  String get comments => headerValues['COMMENTS'] ?? '';
  String get deliveryDate => headerValues['DELIVERY_DATE'] ?? '';

  String get currentOrderTypeRequestKey =>
      selectedOrderType == null ? 'ITEM_ORDER' : normalizeTypeKey(selectedOrderType!);
  bool get isPriceChangeType {
    final k = currentOrderTypeRequestKey;
    return k == 'PRICE_CHANGE' || k == 'TPR';
  }

  bool get isTPRType => currentOrderTypeRequestKey == 'TPR';
  bool get isCreditRequestType => currentOrderTypeRequestKey == 'CREDIT_REQUEST';

  List<OrderControlButton> get controlButtonsForCurrentType {
    final type = selectedOrderType?.toUpperCase();
    if (type == null) return config.controlButtons;
    return config.controlButtons
        .where((b) => b.requestTypes.isEmpty || b.requestTypes.contains(type))
        .toList();
  }

  // ── Totals (port) ────────────────────────────────────────────────────────────
  int get totalItems =>
      orderLines.where((l) => (int.tryParse(l.qty) ?? 0) >= 1).length;
  int get totalItemQty =>
      orderLines.fold(0, (a, l) => a + (int.tryParse(l.qty) ?? 0));
  double get totalEstValue => orderLines.fold(0.0, (a, l) {
        final qty = double.tryParse(l.qty) ?? 0;
        final price = double.tryParse(l.item[ItemRepository.colAdEffective] ?? '') ?? 0;
        return a + qty * price;
      });
  double get totalAllowance => orderLines.fold(0.0, (a, l) {
        final qty = double.tryParse(l.qty) ?? 0;
        final allow = double.tryParse(l.item[ItemRepository.colAllowance] ?? '') ?? 0;
        return a + qty * allow;
      });
  double get totalCube => orderLines.fold(0.0, (a, l) {
        final qty = double.tryParse(l.qty) ?? 0;
        final cube = double.tryParse(l.item[ItemRepository.colCube] ?? '') ?? 0;
        return a + qty * cube;
      });

  String getTotalValue(String key) {
    switch (key.toUpperCase()) {
      case 'ITEM_QTY':
        return '$totalItems';
      case 'CASE_QTY':
        return '$totalItemQty';
      case 'EST_VALUE':
        return totalEstValue.toStringAsFixed(2);
      case 'ALLOWANCE':
        return totalAllowance.toStringAsFixed(2);
      case 'TOTAL_CUBE':
        return totalCube.toStringAsFixed(2);
      default:
        return '—';
    }
  }

  OrderLine? lineFor(Map<String, String> item) {
    for (final l in orderLines) {
      if (identical(l.item, item) || _mapEq(l.item, item)) return l;
    }
    return null;
  }
}

bool _mapEq(Map a, Map b) {
  if (a.length != b.length) return false;
  for (final k in a.keys) {
    if (a[k] != b[k]) return false;
  }
  return true;
}

class OrderEntryController extends Notifier<OrderEntryState> {
  final _dao = PendingOrderDao();

  @override
  OrderEntryState build() {
    final st = OrderEntryState(config: OrderConfig.defaults());
    Future.microtask(loadConfig);
    return st;
  }

  void loadConfig() {
    final session = ref.read(sessionManagerProvider);
    final cfg = OrderConfig.fromLov1Json(session.getLov1ConfigJson());
    state = state.copyWith(config: cfg, configLoaded: true);
  }

  // ── Pre-entry selection ─────────────────────────────────────────────────────
  void selectCustomer(CustomerEntry c) =>
      state = state.copyWith(selectedCustomer: c);

  void selectOrderType(String type) {
    // Native auto-saves previous unsaved lines as UNSENT before starting fresh.
    if (state.orderLines.isNotEmpty) {
      saveCurrentOrder();
    }
    final storeId = state.selectedCustomer?.storeId ??
        ref.read(sessionManagerProvider).getStoreId() ??
        '';
    final ts = _poTimestamp();
    state = state.copyWith(
      orderLines: const [],
      headerValues: {'PO': '$storeId$ts'},
      selectedOrderType: type,
      clearEditingId: true,
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────────
  void setFieldValue(String key, String value) =>
      state = state.copyWith(headerValues: {...state.headerValues, key: value});
  void setPartition(String p) => setFieldValue('PARTITION', p);

  /// Stores an editable tile field (FILL_EDITABLE) value for an item.
  void setCustomField(Map<String, String> item, String key, String value) {
    final code = item[ItemRepository.colItem] ?? '';
    final m = {...state.customFields, '$code|$key': value};
    state = state.copyWith(customFields: m);
  }

  /// Cycles the QTY or CHARGE sort: none → asc → desc → none (switching the
  /// field starts at asc).
  void toggleSort({required bool charge}) {
    final cur = state.activeSort;
    OrderSort next;
    if (charge) {
      next = cur == OrderSort.chargeAsc
          ? OrderSort.chargeDesc
          : cur == OrderSort.chargeDesc
              ? OrderSort.none
              : OrderSort.chargeAsc;
    } else {
      next = cur == OrderSort.qtyAsc
          ? OrderSort.qtyDesc
          : cur == OrderSort.qtyDesc
              ? OrderSort.none
              : OrderSort.qtyAsc;
    }
    state = state.copyWith(activeSort: next);
  }

  List<FieldRow> fieldsForOrderType(String? type) =>
      state.config.fieldsForOrderType(type);

  /// Returns validation errors ([] = valid). Port of validateHeader.
  List<String> validateHeader() {
    final type = state.selectedOrderType;
    if (type == null) return ['No order type selected.'];
    final keys = state.config.mandatoryKeysForType(type);
    final errors = <String>[];
    for (final k in keys) {
      if ((state.headerValues[k] ?? '').trim().isEmpty) {
        final label = state.config.formFields
            .firstWhere((f) => f.fieldKey.toUpperCase() == k,
                orElse: () => FormFieldConfig(fieldKey: k, label: k))
            .label;
        errors.add('$label is required.');
      }
    }
    return errors;
  }

  // ── Order lines (port of addOrUpdateLine / remove / updateQty) ─────────────────
  void addOrUpdateLine(
    Map<String, String> item,
    String qty, {
    String newPrice = '',
    String fromDate = '',
    String toDate = '',
    String crReasonCode = '',
    String crType = '',
    String crInvoiceNumber = '',
    String? alertWatermarkText,
    String? alertBackgroundHex,
  }) {
    final trimQty = qty.trim();
    final lines = [...state.orderLines];
    final idx =
        lines.indexWhere((l) => identical(l.item, item) || _mapEq(l.item, item));
    if (trimQty.isEmpty || trimQty == '0') {
      if (idx >= 0) lines.removeAt(idx);
    } else {
      final existing = idx >= 0 ? lines[idx] : null;
      final line = OrderLine(
        item: item,
        qty: trimQty,
        newPrice: newPrice.trim(),
        tagRequired: existing?.tagRequired ?? '0',
        fromDate: fromDate.trim(),
        toDate: toDate.trim(),
        crReasonCode: crReasonCode.isNotEmpty
            ? crReasonCode
            : (state.isCreditRequestType
                ? (existing?.crReasonCode.isNotEmpty == true
                    ? existing!.crReasonCode
                    : (state.headerValues['CR_REASON_CODE'] ?? ''))
                : ''),
        crType: crType.isNotEmpty
            ? crType
            : (state.isCreditRequestType
                ? (existing?.crType.isNotEmpty == true
                    ? existing!.crType
                    : (state.headerValues['CR_TYPE'] ?? ''))
                : ''),
        crInvoiceNumber: crInvoiceNumber.isNotEmpty
            ? crInvoiceNumber
            : (state.isCreditRequestType
                ? (existing?.crInvoiceNumber.isNotEmpty == true
                    ? existing!.crInvoiceNumber
                    : (state.headerValues['INVOICE#'] ?? ''))
                : ''),
        alertWatermarkText: alertWatermarkText ?? existing?.alertWatermarkText,
        alertBackgroundHex: alertBackgroundHex ?? existing?.alertBackgroundHex,
        partition: existing?.partition ?? state.selectedPartition,
      );
      if (idx >= 0) {
        lines[idx] = line;
      } else {
        lines.add(line);
      }
    }
    state = state.copyWith(orderLines: lines);
  }

  void removeLine(Map<String, String> item) => state = state.copyWith(
      orderLines: state.orderLines
          .where((l) => !identical(l.item, item) && !_mapEq(l.item, item))
          .toList());

  void updateLineQty(Map<String, String> item, String qty) {
    final lines = [...state.orderLines];
    final idx =
        lines.indexWhere((l) => identical(l.item, item) || _mapEq(l.item, item));
    if (idx >= 0) lines[idx] = lines[idx].copyWith(qty: qty.trim());
    state = state.copyWith(orderLines: lines);
  }

  /// Add-to-order with the alert pipeline (port of commitItemWithAlertCheck).
  /// null evaluation → add directly; popup → raise pendingAlert; silent →
  /// add with watermark/background.
  void commitItem(
    Map<String, String> item,
    String qty, {
    String newPrice = '',
    String fromDate = '',
    String toDate = '',
    String crReasonCode = '',
    String crType = '',
    String crInvoiceNumber = '',
  }) {
    final trim = qty.trim();
    if (trim.isEmpty || trim == '0') {
      removeLine(item);
      return;
    }
    final pending = state.pendingAlert;
    if (pending != null && _mapEq(pending.item, item)) return;

    final eval = evaluateAlert(
      item: item,
      qty: qty,
      firstAdd: state.lineFor(item) == null,
      statusConfigs: state.config.itemStatusAlertConfigs,
      alertConfigs: state.config.alertMessagesConfigs,
      allowedMaxQuantity: state.config.allowedMaxQuantity,
    );

    void add({String? wm, String? bg}) => addOrUpdateLine(
          item,
          qty,
          newPrice: newPrice,
          fromDate: fromDate,
          toDate: toDate,
          crReasonCode: crReasonCode,
          crType: crType,
          crInvoiceNumber: crInvoiceNumber,
          alertWatermarkText: wm,
          alertBackgroundHex: bg,
        );

    if (eval == null) {
      add();
      return;
    }
    if (eval.shouldShowPopup) {
      removeLine(item);
      state = state.copyWith(
          pendingAlert: PendingItemStatusAlert(
              item: item, qty: qty, newPrice: newPrice, evaluation: eval));
      return;
    }
    // Silent alert — commit with watermark/background.
    add(
      wm: eval.watermarkText.isNotEmpty ? eval.watermarkText : null,
      bg: eval.backgroundHex.isNotEmpty ? eval.backgroundHex : null,
    );
  }

  Future<void> acceptAlert() async {
    final a = state.pendingAlert;
    if (a == null) return;
    var item = a.item;
    if (a.evaluation.isDiscontinued && a.evaluation.alternateItemId.isNotEmpty) {
      final alt =
          await ref.read(itemRepositoryProvider).queryByExactCode(a.evaluation.alternateItemId);
      if (alt.isNotEmpty) item = alt.first;
    }
    addOrUpdateLine(
      item,
      a.qty,
      newPrice: a.newPrice,
      alertWatermarkText:
          a.evaluation.watermarkText.isNotEmpty ? a.evaluation.watermarkText : null,
      alertBackgroundHex:
          a.evaluation.backgroundHex.isNotEmpty ? a.evaluation.backgroundHex : null,
    );
    state = state.copyWith(clearAlert: true);
  }

  void skipAlert() {
    final a = state.pendingAlert;
    if (a == null) return;
    removeLine(a.item);
    state = state.copyWith(clearAlert: true);
  }

  // ── Mults ───────────────────────────────────────────────────────────────────
  void setMults(String code, List<Map<String, String>> items) =>
      state = state.copyWith(multsScannedCode: code, multsCandidates: items);
  void clearMults() =>
      state = state.copyWith(multsScannedCode: '', multsCandidates: const []);

  // ── Persist (port of saveCurrentOrder) ─────────────────────────────────────────
  /// Serializes the current order to the local DB as UNSENT; returns the new id
  /// (or -1 when there are no lines).
  Future<int> saveCurrentOrder() async {
    final s = state;
    if (s.orderLines.isEmpty) return -1;
    final session = ref.read(sessionManagerProvider);
    final partition = s.selectedPartition;
    final lines = s.orderLines.map((l) {
      final qtyD = double.tryParse(l.qty) ?? 0;
      final price = double.tryParse(l.item[ItemRepository.colAdEffective] ?? '') ?? 0;
      return SavedOrderLine(
        itemNumber: l.item[ItemRepository.colItem]?.trim() ?? '',
        itemDescription: l.item[ItemRepository.colDesc]?.trim() ?? 'UNKNOWN',
        qty: l.qty,
        newPrice: l.newPrice,
        pack: l.item[ItemRepository.colPack]?.trim() ?? '',
        upc: l.item[ItemRepository.colUpc]?.trim() ?? '0',
        storeDepartment: l.item[ItemRepository.colDept]?.trim() ?? partition,
        cube: l.item[ItemRepository.colCube]?.trim() ?? '0.00',
        itemCodeMults: l.item[ItemRepository.colMults]?.trim() ?? '',
        tagRequired: l.tagRequired,
        alertWatermarkText: l.alertWatermarkText ?? '',
        alertBackgroundHex: l.alertBackgroundHex ?? '',
        fromDate: l.fromDate,
        toDate: l.toDate,
        crReasonCode: l.crReasonCode,
        crType: l.crType,
        crInvoiceNumber: l.crInvoiceNumber,
        partition: l.partition.isNotEmpty ? l.partition : partition,
        estimatedValue: (qtyD * price).toStringAsFixed(2),
      );
    }).toList();

    final count = s.totalItems;
    final qty = s.totalItemQty;
    final displayPartition = s.orderLines.isNotEmpty &&
            s.orderLines.first.partition.isNotEmpty
        ? s.orderLines.first.partition
        : partition;

    final entity = PendingOrder(
      storeId: s.selectedCustomer?.storeId ?? session.getStoreId() ?? '',
      orderType: s.currentOrderTypeRequestKey,
      partition: displayPartition,
      poNumber: s.poNumber,
      comments: s.comments,
      deliveryDate: s.deliveryDate,
      adDate: s.headerValues['AD_DATE'] ?? '',
      adId: s.headerValues['AD_ID'] ?? '',
      data1: s.headerValues['DATA1'] ?? '',
      data2: s.headerValues['DATA2'] ?? '',
      data3: s.headerValues['DATA3'] ?? '',
      date1: s.headerValues['DATE1'] ?? '',
      date2: s.headerValues['DATE2'] ?? '',
      status: 'UNSENT',
      linesJson: jsonEncode(lines.map((e) => e.toJson()).toList()),
      itemCount: count,
      totalQty: qty,
      totalValue: s.totalEstValue.toStringAsFixed(2),
      totalCube: s.totalCube.toStringAsFixed(2),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    final id = await _dao.insert(entity);
    final oldEdit = s.editingOrderId;
    if (oldEdit != null && oldEdit != id) await _dao.deleteById(oldEdit);
    return id;
  }

  /// Starts an order from a standing-order template: enriches each (itemNumber,
  /// qty) pair from the item catalog and loads them as order lines.
  Future<void> loadTemplateLines(List<MapEntry<String, String>> template) async {
    final repo = ref.read(itemRepositoryProvider);
    final lines = <OrderLine>[];
    for (final e in template) {
      final matches = await repo.queryByExactCode(e.key);
      final item = matches.isNotEmpty
          ? matches.first
          : {ItemRepository.colItem: e.key, ItemRepository.colDesc: 'Item ${e.key}'};
      lines.add(OrderLine(item: item, qty: e.value, partition: state.selectedPartition));
    }
    final storeId = state.selectedCustomer?.storeId ??
        ref.read(sessionManagerProvider).getStoreId() ??
        '';
    state = state.copyWith(
      selectedOrderType: state.selectedOrderType ?? 'ITEM_ORDER',
      orderLines: lines,
      headerValues: {...state.headerValues, 'PO': '$storeId${_poTimestamp()}'},
    );
  }

  void resetOrder() {
    state = OrderEntryState(config: state.config, configLoaded: state.configLoaded);
  }

  String _poTimestamp() {
    final d = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}${two(d.month)}${two(d.day)}${two(d.hour)}';
  }
}

final orderEntryControllerProvider =
    NotifierProvider<OrderEntryController, OrderEntryState>(
        OrderEntryController.new);

/// Shared item repository.
final itemRepositoryProvider = Provider<ItemRepository>((ref) => ItemRepository());
