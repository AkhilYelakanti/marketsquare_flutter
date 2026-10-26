import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/device_meta.dart';
import '../../core/network/api_client.dart';
import '../../data/db/item_repository.dart';
import '../../data/db/pending_order.dart';
import '../../data/db/pending_order_dao.dart';
import '../../data/models/order_models.dart';
import '../../data/repository/order_repository.dart';
import '../../data/session/session_providers.dart';

enum ApprovalLoad { idle, loading, error }

class ApprovalsState {
  final bool waiting; // true = WAITING mode, false = APPROVED
  final List<ApprovalOrderSummary> orders;
  final ApprovalLoad loadState;
  final Set<String> selectedIds;
  final bool deleting;
  final ApiItemOrder? approvedDetail;
  final bool loadingDetail;
  final String error;

  const ApprovalsState({
    this.waiting = true,
    this.orders = const [],
    this.loadState = ApprovalLoad.idle,
    this.selectedIds = const {},
    this.deleting = false,
    this.approvedDetail,
    this.loadingDetail = false,
    this.error = '',
  });

  ApprovalsState copyWith({
    bool? waiting,
    List<ApprovalOrderSummary>? orders,
    ApprovalLoad? loadState,
    Set<String>? selectedIds,
    bool? deleting,
    ApiItemOrder? approvedDetail,
    bool? loadingDetail,
    bool clearDetail = false,
    String? error,
  }) =>
      ApprovalsState(
        waiting: waiting ?? this.waiting,
        orders: orders ?? this.orders,
        loadState: loadState ?? this.loadState,
        selectedIds: selectedIds ?? this.selectedIds,
        deleting: deleting ?? this.deleting,
        approvedDetail: clearDetail ? null : (approvedDetail ?? this.approvedDetail),
        loadingDetail: loadingDetail ?? this.loadingDetail,
        error: error ?? this.error,
      );
}

/// Port of `ApprovalsListViewModel`: waiting/approved lists, single-select,
/// delete-waiting, load approved detail, and load-waiting-order-for-editing.
class ApprovalsController extends Notifier<ApprovalsState> {
  late final OrderRepository _repo = OrderRepository(ApiClient());
  final _dao = PendingOrderDao();
  final _itemRepo = ItemRepository();

  @override
  ApprovalsState build() => const ApprovalsState();

  /// Mints a fresh auth token before an order/approval REST call. The stored
  /// token expires on long-lived sessions, which the approval host rejects with
  /// HTTP 401 invalid_token; a fresh token from ACCESS_TOKEN fixes that.
  Future<void> _refreshToken() async {
    final session = ref.read(sessionManagerProvider);
    final tokenUrl = session.getServiceUrl('ACCESS_TOKEN');
    final serviceId = session.getServiceId();
    final userId = session.getUserId();
    if (tokenUrl == null || serviceId == null || userId == null) return;
    final t = await ref.read(loginRepositoryProvider).getAuthToken(
          tokenUrl: tokenUrl,
          serviceId: serviceId,
          deviceId: await deviceId(),
          accessId: userId,
          versionId: await versionId(),
        );
    if (t.isSuccess) await session.saveAuthToken(t.value!.accessToken);
  }

  Future<void> load(bool waiting) async {
    state = state.copyWith(
        waiting: waiting,
        orders: const [],
        selectedIds: const {},
        loadState: ApprovalLoad.loading);
    await _refreshToken();
    final session = ref.read(sessionManagerProvider);
    final res = await _repo.fetchApprovals(
      session: session,
      waiting: waiting,
      deviceId: await deviceId(),
      versionId: await versionId(),
    );
    if (res.isSuccess) {
      state = state.copyWith(
          orders: res.value!.ordersList, loadState: ApprovalLoad.idle, error: '');
    } else {
      state = state.copyWith(
          loadState: ApprovalLoad.error, error: '${res.error}');
    }
  }

  void toggleSelection(String confirmationId) {
    final sel = state.selectedIds.contains(confirmationId)
        ? <String>{}
        : {confirmationId};
    state = state.copyWith(selectedIds: sel);
  }

  Future<bool> deleteSelected() async {
    if (state.selectedIds.isEmpty || state.deleting) return false;
    final toDelete =
        state.orders.where((o) => state.selectedIds.contains(o.confirmationId)).toList();
    state = state.copyWith(deleting: true);
    await _refreshToken();
    final res = await _repo.deleteWaitingApprovals(
      session: ref.read(sessionManagerProvider),
      orders: toDelete,
      deviceId: await deviceId(),
      versionId: await versionId(),
    );
    if (res.isSuccess) {
      state = state.copyWith(
        orders: state.orders
            .where((o) => !state.selectedIds.contains(o.confirmationId))
            .toList(),
        selectedIds: const {},
        deleting: false,
      );
      return true;
    }
    state = state.copyWith(deleting: false);
    return false;
  }

  Future<void> loadApprovedDetail(String confirmationId) async {
    state = state.copyWith(loadingDetail: true, clearDetail: true);
    await _refreshToken();
    final res = await _repo.fetchApprovalOrder(
      session: ref.read(sessionManagerProvider),
      confirmationId: confirmationId,
      waiting: false,
      deviceId: await deviceId(),
      versionId: await versionId(),
    );
    state = state.copyWith(
        loadingDetail: false, approvedDetail: res.isSuccess ? res.value : null);
  }

  void clearApprovedDetail() => state = state.copyWith(clearDetail: true);

  /// Fetches a waiting order, saves it to the local DB as UNSENT (enriching lines
  /// from the item catalog), and returns the new pending-order id (or -1).
  Future<int> loadOrderForEditing(String confirmationId) async {
    await _refreshToken();
    final session = ref.read(sessionManagerProvider);
    final res = await _repo.fetchApprovalOrder(
      session: session,
      confirmationId: confirmationId,
      waiting: true,
      deviceId: await deviceId(),
      versionId: await versionId(),
    );
    if (!res.isSuccess) return -1;
    final order = res.value!;
    final header = order.header;

    final lines = <SavedOrderLine>[];
    for (final d in order.details) {
      final matches = await _itemRepo.queryByExactCode(d.itemNumber);
      final row = matches.isNotEmpty ? matches.first : null;
      lines.add(SavedOrderLine(
        itemNumber: d.itemNumber,
        itemDescription: (row?[ItemRepository.colDesc]?.isNotEmpty ?? false)
            ? row![ItemRepository.colDesc]!
            : d.itemDescription,
        qty: d.quantity.isNotEmpty ? d.quantity : '1',
        pack: row?[ItemRepository.colPack] ?? '',
        upc: row?[ItemRepository.colUpc] ?? d.itemUpc,
        storeDepartment: row?[ItemRepository.colDept] ?? d.storeDepartment,
        cube: row?[ItemRepository.colCube] ?? '0.00',
        tagRequired: d.tagRequired,
      ));
    }
    final totalQty = lines.fold<int>(0, (a, l) => a + (int.tryParse(l.qty) ?? 1));
    final entity = PendingOrder(
      storeId: session.getStoreId() ?? '',
      orderType: header?.requestType ?? '',
      partition: header?.storePartition ?? '',
      poNumber: header?.custPoNumber ?? '',
      comments: header?.comment ?? '',
      deliveryDate: header?.requestedDeliveryDate ?? '',
      status: 'UNSENT',
      linesJson: jsonEncode(lines.map((e) => e.toJson()).toList()),
      itemCount: lines.length,
      totalQty: totalQty,
      totalValue: header?.totalEstimateValue ?? '0.00',
      createdAt: DateTime.now().millisecondsSinceEpoch,
      confirmationNumber: confirmationId,
    );
    return _dao.insert(entity);
  }
}

final approvalsControllerProvider =
    NotifierProvider<ApprovalsController, ApprovalsState>(ApprovalsController.new);
