import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/device_meta.dart';
import '../../core/network/api_client.dart';
import '../../data/models/order_models.dart';
import '../../data/repository/order_repository.dart';
import '../../data/session/session_providers.dart';
import '../orderentry/order_entry_controller.dart';

class StoreOrdersState {
  final CustomerEntry? customer;
  final List<OrderSummary> orders;
  final bool loadingOrders;
  final String ordersError;
  final OrderSummary? selectedOrder;
  final StoreOrderDetailResponse? detail;
  final bool loadingDetail;
  final String detailError;

  const StoreOrdersState({
    this.customer,
    this.orders = const [],
    this.loadingOrders = false,
    this.ordersError = '',
    this.selectedOrder,
    this.detail,
    this.loadingDetail = false,
    this.detailError = '',
  });

  StoreOrdersState copyWith({
    CustomerEntry? customer,
    List<OrderSummary>? orders,
    bool? loadingOrders,
    String? ordersError,
    OrderSummary? selectedOrder,
    StoreOrderDetailResponse? detail,
    bool? loadingDetail,
    String? detailError,
    bool clearDetail = false,
  }) =>
      StoreOrdersState(
        customer: customer ?? this.customer,
        orders: orders ?? this.orders,
        loadingOrders: loadingOrders ?? this.loadingOrders,
        ordersError: ordersError ?? this.ordersError,
        selectedOrder: selectedOrder ?? this.selectedOrder,
        detail: clearDetail ? null : (detail ?? this.detail),
        loadingDetail: loadingDetail ?? this.loadingDetail,
        detailError: detailError ?? this.detailError,
      );
}

/// Port of `ViewAllOrdersViewModel`: customer → recent orders → order detail.
class StoreOrdersController extends Notifier<StoreOrdersState> {
  late final OrderRepository _repo = OrderRepository(ApiClient());

  @override
  StoreOrdersState build() => const StoreOrdersState();

  List<CustomerEntry> get customers =>
      ref.read(orderEntryControllerProvider).config.customers;

  Future<void> selectCustomer(CustomerEntry c) async {
    state = state.copyWith(customer: c, orders: const [], ordersError: '');
    await fetchOrders();
  }

  Future<void> fetchOrders() async {
    final c = state.customer;
    if (c == null) return;
    state = state.copyWith(loadingOrders: true, ordersError: '');
    final res = await _repo.fetchRecentOrders(
      session: ref.read(sessionManagerProvider),
      storeId: c.storeId,
      deviceId: await deviceId(),
      versionId: await versionId(),
    );
    if (res.isSuccess) {
      final r = res.value!;
      state = state.copyWith(
        loadingOrders: false,
        orders: r.data,
        ordersError: r.data.isEmpty ? (r.statusMsg.isEmpty ? 'No orders found.' : r.statusMsg) : '',
      );
    } else {
      state = state.copyWith(loadingOrders: false, ordersError: 'Failed to load orders.');
    }
  }

  Future<void> selectOrderAndFetch(OrderSummary order) async {
    state = state.copyWith(
        selectedOrder: order, loadingDetail: true, detailError: '', clearDetail: true);
    final c = state.customer!;
    final res = await _repo.retrieveStoreOrderDetail(
      session: ref.read(sessionManagerProvider),
      storeId: c.storeId,
      confirmationId: order.confirmationId,
      transactionId: order.transactionId,
      deviceId: await deviceId(),
      versionId: await versionId(),
    );
    state = state.copyWith(
      loadingDetail: false,
      detail: res.isSuccess ? res.value : null,
      detailError: res.isSuccess ? '' : 'Failed to load order detail.',
    );
  }
}

final storeOrdersControllerProvider =
    NotifierProvider<StoreOrdersController, StoreOrdersState>(StoreOrdersController.new);
