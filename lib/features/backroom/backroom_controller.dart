import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/backroom_dao.dart';
import '../../data/db/backroom_item.dart';
import '../orderentry/order_entry_controller.dart';

class BackroomState {
  final List<String> departments;
  final String selectedDepartment;
  final List<BackroomItem> itemsByDepartment;
  final List<BackroomItem> allItems;
  final String? message;

  const BackroomState({
    this.departments = const [],
    this.selectedDepartment = '',
    this.itemsByDepartment = const [],
    this.allItems = const [],
    this.message,
  });

  BackroomState copyWith({
    List<String>? departments,
    String? selectedDepartment,
    List<BackroomItem>? itemsByDepartment,
    List<BackroomItem>? allItems,
    String? message,
    bool clearMessage = false,
  }) =>
      BackroomState(
        departments: departments ?? this.departments,
        selectedDepartment: selectedDepartment ?? this.selectedDepartment,
        itemsByDepartment: itemsByDepartment ?? this.itemsByDepartment,
        allItems: allItems ?? this.allItems,
        message: clearMessage ? null : (message ?? this.message),
      );
}

/// Port of `BackroomViewModel`. Fully local (no network). Departments come from
/// the LOV1 store-partition list (via OrderConfig); manual entry is also allowed.
class BackroomController extends Notifier<BackroomState> {
  final _dao = BackroomDao();

  @override
  BackroomState build() {
    Future.microtask(_init);
    return const BackroomState();
  }

  Future<void> _init() async {
    final cfg = ref.read(orderEntryControllerProvider).config;
    final depts = cfg.deptList.isNotEmpty ? cfg.deptList : cfg.partitions;
    state = state.copyWith(departments: depts, allItems: await _dao.getAll());
  }

  Future<void> selectDepartment(String dept) async {
    state = state.copyWith(selectedDepartment: dept);
    state = state.copyWith(itemsByDepartment: await _dao.getByDepartment(dept));
  }

  Future<void> refresh() async {
    state = state.copyWith(allItems: await _dao.getAll());
    if (state.selectedDepartment.isNotEmpty) {
      state = state.copyWith(
          itemsByDepartment: await _dao.getByDepartment(state.selectedDepartment));
    }
  }

  /// Adds qty to an existing (dept,itemCode) record, or creates one.
  Future<bool> addOrUpdateItem(
      String department, String itemCode, String itemDescription, int quantity) async {
    if (department.isEmpty || itemCode.isEmpty || quantity <= 0) {
      state = state.copyWith(message: 'Department, item code, and quantity are required.');
      return false;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final existing = await _dao.getByDeptAndCode(department, itemCode);
    if (existing != null) {
      await _dao.update(existing.copyWith(
        quantity: existing.quantity + quantity,
        itemDescription: itemDescription.isEmpty ? existing.itemDescription : itemDescription,
        updatedAt: now,
      ));
    } else {
      await _dao.insert(BackroomItem(
        department: department,
        itemCode: itemCode,
        itemDescription: itemDescription,
        quantity: quantity,
        createdAt: now,
        updatedAt: now,
      ));
    }
    await refresh();
    state = state.copyWith(message: 'Item saved.');
    return true;
  }

  /// Removes one unit; deletes the record when it reaches 0.
  Future<void> pullItem(BackroomItem item) async {
    if (item.quantity <= 1) {
      await _dao.deleteById(item.id);
    } else {
      await _dao.update(item.copyWith(
          quantity: item.quantity - 1, updatedAt: DateTime.now().millisecondsSinceEpoch));
    }
    await refresh();
  }

  Future<void> clearByDepartment(String dept) async {
    await _dao.deleteByDepartment(dept);
    await refresh();
    state = state.copyWith(message: '$dept inventory cleared.');
  }

  Future<void> clearAll() async {
    await _dao.deleteAll();
    state = state.copyWith(
        allItems: const [],
        itemsByDepartment: const [],
        message: 'All backroom inventory cleared.');
  }

  void clearMessage() => state = state.copyWith(clearMessage: true);
}

final backroomControllerProvider =
    NotifierProvider<BackroomController, BackroomState>(BackroomController.new);
