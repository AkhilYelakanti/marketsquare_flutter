import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/device_meta.dart';
import '../../core/network/api_client.dart';
import '../../data/db/pending_order.dart';
import '../../data/db/pending_order_dao.dart';
import '../../data/models/order_models.dart';
import '../../data/repository/order_repository.dart';
import '../../data/session/session_providers.dart';
import '../orderentry/order_entry_controller.dart';

enum SendInflight { idle, checkingRecommended, checkingOm }

/// Where the pre-submit pipeline decided to route next.
enum SendStep { proceedSubmit, recommended, shortfall }

class SendResult {
  final SendStep step;
  final int orderId;
  const SendResult(this.step, this.orderId);
}

class SendOrdersState {
  final List<PendingOrder> orders;
  final Set<int> selectedIds;
  final SendInflight inflight;
  final List<RecommendedItemEntry> recommendedItems;
  final int recommendedOrderId;
  final String omShortfallHtml;
  final int omShortfallOrderId;

  const SendOrdersState({
    this.orders = const [],
    this.selectedIds = const {},
    this.inflight = SendInflight.idle,
    this.recommendedItems = const [],
    this.recommendedOrderId = -1,
    this.omShortfallHtml = '',
    this.omShortfallOrderId = -1,
  });

  SendOrdersState copyWith({
    List<PendingOrder>? orders,
    Set<int>? selectedIds,
    SendInflight? inflight,
    List<RecommendedItemEntry>? recommendedItems,
    int? recommendedOrderId,
    String? omShortfallHtml,
    int? omShortfallOrderId,
  }) =>
      SendOrdersState(
        orders: orders ?? this.orders,
        selectedIds: selectedIds ?? this.selectedIds,
        inflight: inflight ?? this.inflight,
        recommendedItems: recommendedItems ?? this.recommendedItems,
        recommendedOrderId: recommendedOrderId ?? this.recommendedOrderId,
        omShortfallHtml: omShortfallHtml ?? this.omShortfallHtml,
        omShortfallOrderId: omShortfallOrderId ?? this.omShortfallOrderId,
      );

  bool get hasSelectedUnsent =>
      selectedIds.isNotEmpty && orders.any((o) => selectedIds.contains(o.id));
  int get firstSelectedId =>
      selectedIds.isEmpty ? -1 : selectedIds.first;
}

/// Port of `SendOrdersViewModel`: lists UNSENT orders and runs the pre-submit
/// pipeline (recommended items → order minimum → submit), all fail-open.
class SendOrdersController extends Notifier<SendOrdersState> {
  final _dao = PendingOrderDao();
  late final OrderRepository _repo = OrderRepository(ApiClient());

  @override
  SendOrdersState build() {
    Future.microtask(() => loadOrders());
    return const SendOrdersState();
  }

  Future<void> loadOrders({int autoSelectId = -1}) async {
    final loaded = await _dao.getUnsent();
    final sel = (autoSelectId != -1 && loaded.any((o) => o.id == autoSelectId))
        ? {autoSelectId}
        : <int>{};
    state = state.copyWith(orders: loaded, selectedIds: sel);
  }

  void initCurrentOrder(int id) => loadOrders(autoSelectId: id);

  void toggleSelection(int id) {
    final s = {...state.selectedIds};
    if (s.contains(id)) {
      s.remove(id);
    } else {
      s.add(id);
    }
    state = state.copyWith(selectedIds: s);
  }

  Future<void> deleteOrder(int id) async {
    await _dao.deleteById(id);
    final s = {...state.selectedIds}..remove(id);
    state = state.copyWith(selectedIds: s);
    await loadOrders();
  }

  bool get isApprovalSubmit =>
      ref.read(orderEntryControllerProvider).config.isApprovalSubmit;

  /// Runs the pre-submit pipeline; returns the next step for the screen to route.
  Future<SendResult> beginSend(int orderId) async {
    if (orderId == -1) return SendResult(SendStep.proceedSubmit, orderId);
    final order = await _dao.getById(orderId);
    if (order == null) return SendResult(SendStep.proceedSubmit, orderId);

    final session = ref.read(sessionManagerProvider);
    final config = ref.read(orderEntryControllerProvider).config;
    final dev = await deviceId();
    final ver = await versionId();

    // Check B1 — Recommended Items.
    if (config.isRecommendedItemsCheckEnabled(order.orderType)) {
      state = state.copyWith(inflight: SendInflight.checkingRecommended);
      final res = await _repo.preRecommendedItemsCheck(
          session: session, order: order, deviceId: dev, versionId: ver);
      state = state.copyWith(inflight: SendInflight.idle);
      if (res.isSuccess && res.value!.isNotEmpty) {
        state = state.copyWith(
            recommendedItems: res.value!, recommendedOrderId: orderId);
        return SendResult(SendStep.recommended, orderId);
      }
      // empty / fail-open → fall through
    }
    return _runOmCheck(orderId, order, session, config, dev, ver);
  }

  /// Resumes after RecommendedItemsScreen: append lines, then run OM check.
  Future<SendResult> addRecommendedItemsAndContinue(
      int orderId, List<SavedOrderLine> newLines) async {
    if (newLines.isNotEmpty) {
      final order = await _dao.getById(orderId);
      if (order != null) {
        final existing = _decode(order.linesJson);
        for (final nl in newLines) {
          final idx = existing.indexWhere((e) => e.itemNumber == nl.itemNumber);
          if (idx >= 0) {
            existing[idx] = nl;
          } else {
            existing.add(nl);
          }
        }
        await _dao.update(PendingOrder.fromMap({
          ...order.toMap(),
          'id': order.id,
          'linesJson': jsonEncode(existing.map((e) => e.toJson()).toList()),
        }));
      }
    }
    final order = await _dao.getById(orderId);
    if (order == null) {
      clearRecommended();
      return SendResult(SendStep.proceedSubmit, orderId);
    }
    final session = ref.read(sessionManagerProvider);
    final config = ref.read(orderEntryControllerProvider).config;
    return _runOmCheck(orderId, order, session, config,
        await deviceId(), await versionId());
  }

  Future<SendResult> _runOmCheck(int orderId, PendingOrder order, session,
      config, String dev, String ver) async {
    if (!config.isOrderMinimumCheckEnabled(order.orderType)) {
      clearRecommended();
      return SendResult(SendStep.proceedSubmit, orderId);
    }
    state = state.copyWith(inflight: SendInflight.checkingOm);
    final res = await _repo.preOmCheck(
        session: session, order: order, deviceId: dev, versionId: ver);
    state = state.copyWith(inflight: SendInflight.idle);
    clearRecommended();
    if (res.isSuccess && res.value!.isShortfall) {
      state = state.copyWith(
          omShortfallHtml: res.value!.html, omShortfallOrderId: orderId);
      return SendResult(SendStep.shortfall, orderId);
    }
    return SendResult(SendStep.proceedSubmit, orderId); // fail-open
  }

  void clearRecommended() =>
      state = state.copyWith(recommendedItems: const [], recommendedOrderId: -1);
  void clearShortfall() =>
      state = state.copyWith(omShortfallHtml: '', omShortfallOrderId: -1);

  List<SavedOrderLine> _decode(String json) {
    try {
      return (jsonDecode(json) as List)
          .map((e) => SavedOrderLine.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}

final sendOrdersControllerProvider =
    NotifierProvider<SendOrdersController, SendOrdersState>(
        SendOrdersController.new);
