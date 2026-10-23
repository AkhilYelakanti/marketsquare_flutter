import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/device_meta.dart';
import '../../core/network/api_client.dart';
import '../../data/db/item_repository.dart';
import '../../data/repository/order_repository.dart';
import '../../data/session/session_providers.dart';
import 'order_entry_controller.dart';

class StandingOrdersState {
  final List<String> names;
  final bool loading;
  final String? message;
  const StandingOrdersState({this.names = const [], this.loading = false, this.message});
  StandingOrdersState copyWith({List<String>? names, bool? loading, String? message, bool clearMsg = false}) =>
      StandingOrdersState(
        names: names ?? this.names,
        loading: loading ?? this.loading,
        message: clearMsg ? null : (message ?? this.message),
      );
}

/// Port of `StandingOrdersViewModel` (favourite-order templates).
class StandingOrdersController extends Notifier<StandingOrdersState> {
  late final OrderRepository _repo = OrderRepository(ApiClient());

  @override
  StandingOrdersState build() => const StandingOrdersState();

  String get _storeId => ref.read(sessionManagerProvider).getActiveStoreId();

  Future<void> loadNames() async {
    state = state.copyWith(loading: true, clearMsg: true);
    final res = await _repo.fetchFavouriteOrderNames(
      session: ref.read(sessionManagerProvider),
      storeId: _storeId,
      deviceId: await deviceId(),
      versionId: await versionId(),
    );
    state = state.copyWith(
        loading: false,
        names: res.isSuccess ? res.value! : const [],
        message: res.isSuccess ? null : 'Failed to load templates.');
  }

  /// Saves the current in-memory order as a template.
  Future<bool> saveCurrentAsTemplate(String name) async {
    final order = ref.read(orderEntryControllerProvider);
    if (order.orderLines.isEmpty) {
      state = state.copyWith(message: 'No items to save.');
      return false;
    }
    final lines = order.orderLines
        .map((l) => MapEntry(
            l.item[ItemRepository.colItem] ?? '', l.qty))
        .where((e) => e.key.isNotEmpty)
        .toList();
    final res = await _repo.saveFavouriteOrder(
      session: ref.read(sessionManagerProvider),
      orderName: name,
      poNumber: order.poNumber,
      deliveryDate: order.deliveryDate,
      comments: order.comments,
      storeId: _storeId,
      deviceId: await deviceId(),
      versionId: await versionId(),
      lines: lines,
    );
    state = state.copyWith(message: res.isSuccess ? 'Template "$name" saved.' : 'Save failed.');
    if (res.isSuccess) await loadNames();
    return res.isSuccess;
  }

  Future<void> deleteTemplate(String name) async {
    final res = await _repo.deleteFavouriteOrder(
      session: ref.read(sessionManagerProvider),
      orderName: name,
      storeId: _storeId,
      deviceId: await deviceId(),
      versionId: await versionId(),
    );
    state = state.copyWith(message: res.isSuccess ? 'Template "$name" deleted.' : 'Delete failed.');
    if (res.isSuccess) await loadNames();
  }

  /// Fetches a template and loads its lines into the order editor. Returns true
  /// on success so the caller can navigate to Order Filling.
  Future<bool> startFromTemplate(String name) async {
    final res = await _repo.fetchFavouriteOrder(
      session: ref.read(sessionManagerProvider),
      orderName: name,
      storeId: _storeId,
      deviceId: await deviceId(),
      versionId: await versionId(),
    );
    if (!res.isSuccess) {
      state = state.copyWith(message: 'Failed to load template.');
      return false;
    }
    await ref.read(orderEntryControllerProvider.notifier).loadTemplateLines(res.value!);
    return true;
  }

  void clearMessage() => state = state.copyWith(clearMsg: true);
}

final standingOrdersControllerProvider =
    NotifierProvider<StandingOrdersController, StandingOrdersState>(
        StandingOrdersController.new);
