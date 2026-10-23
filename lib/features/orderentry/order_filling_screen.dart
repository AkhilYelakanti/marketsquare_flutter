import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db/item_repository.dart';
import '../../data/models/order_models.dart';
import '../../router/app_routes.dart';
import '../../widgets/hardware_scan_listener.dart';
import '../../widgets/scanner_sheet.dart';
import 'field_resolver.dart';
import 'order_entry_controller.dart';
import 'order_widgets.dart';
import 'tile_widgets.dart';

/// Port of native `OrderFillingScreen` (core): header summary, order-lines list
/// with qty editing, totals bar, control buttons, scan-to-add, and SEND which
/// persists the order and continues to Send Orders.
///
/// The native screen also renders catalog tile cards + the item-status/qty
/// alert pipeline; those ride on the item-catalog module and are simplified here.
class OrderFillingScreen extends ConsumerWidget {
  const OrderFillingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = Theme.of(context).colorScheme.primary;
    final st = ref.watch(orderEntryControllerProvider);
    final ctrl = ref.read(orderEntryControllerProvider.notifier);
    final lines = st.sortedLines; // active QTY/CHARGE sort, else newest-first

    return Scaffold(
      appBar: orderAppBar(
        subtitle: st.selectedOrderType ?? 'ORDER',
        third: st.selectedCustomer != null ? 'Store: ${st.selectedCustomer!.storeId}' : null,
        height: 80,
      ),
      // Totals bar + action toolbar pinned to the bottom (native order).
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TotalsBar(primary: primary),
          _BottomControls(
            onBack: () => context.pop(),
            onSearch: () => context.push(Routes.orderItemSearch),
            onSend: () => _send(context, ref),
            extra: st.controlButtonsForCurrentType,
            onControl: (b) => _handleControl(context, ref, b),
          ),
        ],
      ),
      body: Column(
        children: [
          // Partition / QTY / CHARGE sort summary bar.
          _SortBar(
            primary: primary,
            partition: st.selectedPartition,
            sort: st.activeSort,
            onPartition: () => context.push(Routes.selectPartition),
            onQtySort: () => ctrl.toggleSort(charge: false),
            onChargeSort: () => ctrl.toggleSort(charge: true),
            onSearch: () => context.push(Routes.orderItemSearch),
          ),
          // Inline "tap to key item" entry (item number / UPC) → add.
          _ItemEntryRow(
            primary: primary,
            onSubmit: (code) => _addByCode(context, ref, code),
            onSearch: () => context.push(Routes.orderItemSearch),
          ),
          const Divider(height: 1),
          Expanded(
            child: lines.isEmpty
                ? const Center(
                    child: Text('No items yet.\nKey an item or use SEARCH / SCAN.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey)))
                : ListView.separated(
                    itemCount: lines.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 0.5, color: Color(0xFFEEEEEE)),
                    // Config-driven tile (LOV tile layout for this order type).
                    itemBuilder: (_, i) => OrderItemTile(item: lines[i].item),
                  ),
          ),
          const OrderAlertHost(),
          HardwareScanListener(onScan: (code) => _addByCode(context, ref, code)),
        ],
      ),
    );
  }

  Future<void> _scanAdd(BuildContext context, WidgetRef ref) async {
    final code = await ScannerSheet.scan(context);
    if (code == null || !context.mounted) return;
    await _addByCode(context, ref, code);
  }

  Future<void> _addByCode(BuildContext context, WidgetRef ref, String code) async {
    final repo = ref.read(itemRepositoryProvider);
    final ctrl = ref.read(orderEntryControllerProvider.notifier);
    final st = ref.read(orderEntryControllerProvider);
    var matches = await repo.queryByExactCode(code);
    // restrictDepartment=Y: only items in the selected partition's department
    // are orderable (native post-query partition filter).
    if (st.config.deptRestricted && matches.isNotEmpty) {
      final part = st.selectedPartition.toUpperCase();
      matches = matches.where((m) {
        final d = resolveItemField('DEPT_NAME', m);
        final dept = d.isNotEmpty ? d : resolveItemField('DEPT', m);
        return dept.toUpperCase() == part;
      }).toList();
    }
    if (!context.mounted) return;
    if (matches.isEmpty) {
      // Not on file: alert the user (native beeps twice), but keep the keyed
      // code in the item column with a "NOT ON FILE" description — the item can
      // still be ordered.
      await SystemSound.play(SystemSoundType.alert);
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 160));
      await SystemSound.play(SystemSoundType.alert);
      await HapticFeedback.heavyImpact();
      ctrl.commitItem(
          {ItemRepository.colItem: code, ItemRepository.colDesc: 'NOT ON FILE'}, '1');
    } else if (matches.length == 1) {
      ctrl.commitItem(matches.first, '1');
    } else {
      ctrl.setMults(code, matches);
      context.push(Routes.orderMultsReturned);
    }
  }

  /// Routes a LOV1 control-button tap to its action (native parity for the
  /// known buttons; unmapped ones surface a notice rather than dead-tapping).
  void _handleControl(BuildContext context, WidgetRef ref, OrderControlButton b) {
    switch (b.key.toUpperCase()) {
      case 'PARTITION':
        context.push(Routes.selectPartition);
      case 'DEALS':
        context.push(Routes.orderSearchDeals);
      case 'NEW':
        context.push(Routes.orderSearchNewItems);
      case 'SAVED':
        context.push(Routes.orderSavedItems);
      case 'SEARCH':
        context.push(Routes.orderItemSearch);
      case 'SCAN':
        _scanAdd(context, ref);
      case 'SEND':
      case 'SUBMIT':
      case 'APPROVE':
        _send(context, ref);
      default:
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${b.label} not wired yet')));
    }
  }

  Future<void> _send(BuildContext context, WidgetRef ref) async {
    final ctrl = ref.read(orderEntryControllerProvider.notifier);
    final st = ref.read(orderEntryControllerProvider);
    if (st.orderLines.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Add at least one item.')));
      return;
    }
    final id = await ctrl.saveCurrentOrder();
    if (!context.mounted) return;
    // Continue to Send Orders (placeholder until that module is ported).
    context.push('${Routes.sendOrders}?currentOrderId=$id');
  }
}

/// Partition / QTY / CHARGE sort bar + SEARCH (native filter-sort bar).
class _SortBar extends StatelessWidget {
  final Color primary;
  final String partition;
  final OrderSort sort;
  final VoidCallback onPartition;
  final VoidCallback onQtySort;
  final VoidCallback onChargeSort;
  final VoidCallback onSearch;
  const _SortBar({
    required this.primary,
    required this.partition,
    required this.sort,
    required this.onPartition,
    required this.onQtySort,
    required this.onChargeSort,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    Widget sortToggle(String label, VoidCallback onTap, bool asc, bool desc) {
      final active = asc || desc;
      return InkWell(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$label ',
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey)),
            Text(asc ? '↑' : (desc ? '↓' : '—'),
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: active ? primary : Colors.black54)),
          ],
        ),
      );
    }

    return Container(
      color: const Color(0xFFEDEDED),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onPartition,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('PARTITION ',
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey)),
                  Flexible(
                    child: Text(partition,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold, color: primary)),
                  ),
                ],
              ),
            ),
          ),
          sortToggle('QTY', onQtySort, sort == OrderSort.qtyAsc,
              sort == OrderSort.qtyDesc),
          const SizedBox(width: 12),
          sortToggle('CHARGE', onChargeSort, sort == OrderSort.chargeAsc,
              sort == OrderSort.chargeDesc),
          const SizedBox(width: 10),
          SizedBox(
            height: 30,
            child: ElevatedButton(
              onPressed: onSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              child: const Text('SEARCH', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Inline "tap to key item" entry: key an item number / UPC → fetch + add.
class _ItemEntryRow extends StatefulWidget {
  final Color primary;
  final ValueChanged<String> onSubmit;
  final VoidCallback onSearch;
  const _ItemEntryRow(
      {required this.primary, required this.onSubmit, required this.onSearch});

  @override
  State<_ItemEntryRow> createState() => _ItemEntryRowState();
}

class _ItemEntryRowState extends State<_ItemEntryRow> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _go() {
    final c = _ctrl.text.trim();
    if (c.isEmpty) return;
    widget.onSubmit(c);
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
                color: Color(0xFF9E9E9E), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const Icon(Icons.apps, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _ctrl,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _go(),
              decoration: const InputDecoration(
                hintText: 'tap to key item',
                isDense: true,
                border: UnderlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _go,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: widget.primary, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: const Icon(Icons.search, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalsBar extends ConsumerWidget {
  final Color primary;
  const _TotalsBar({required this.primary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(orderEntryControllerProvider);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: primary.withValues(alpha: 0.06),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (final t in st.config.totalFieldsForType(st.selectedOrderType))
            Column(
              children: [
                Text('${t.prefix}${st.getTotalValue(t.key)}',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold, color: primary)),
                Text(t.label,
                    style: const TextStyle(fontSize: 10, color: Colors.black54)),
              ],
            ),
        ],
      ),
    );
  }
}

class _BottomControls extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onSearch;
  final VoidCallback onSend;
  final List<OrderControlButton> extra;
  final void Function(OrderControlButton) onControl;
  const _BottomControls({
    required this.onBack,
    required this.onSearch,
    required this.onSend,
    required this.extra,
    required this.onControl,
  });

  @override
  State<_BottomControls> createState() => _BottomControlsState();

  static IconData _iconFor(OrderControlButton b) {
    final k = (b.icon.isNotEmpty ? b.icon : b.key).toLowerCase();
    switch (k) {
      case 'tune':
      case 'partition':
        return Icons.tune;
      case 'local_offer':
      case 'deals':
        return Icons.local_offer;
      case 'link':
      case 'linked':
        return Icons.link;
      case 'bookmark':
      case 'saved':
        return Icons.bookmark_border;
      case 'scan':
        return Icons.qr_code_scanner;
      case 'add':
      case 'new':
        return Icons.add;
      case 'send':
      case 'submit':
        return Icons.send;
      case 'search':
        return Icons.search;
      case 'thumb_up':
      case 'approve':
        return Icons.thumb_up_alt_outlined;
      default:
        return Icons.radio_button_unchecked;
    }
  }

}

class _BottomControlsState extends State<_BottomControls> {
  bool _expanded = false;

  Widget _btn(IconData icon, String label, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    // BACK / SEARCH / SEND are default; LOV control buttons fill in between.
    const baseKeys = {'BACK', 'SEARCH', 'SEND'};
    final extras =
        widget.extra.where((b) => !baseKeys.contains(b.key.toUpperCase())).toList();
    final extraBtns = [
      for (final b in extras)
        _btn(_BottomControls._iconFor(b), b.label.toUpperCase(),
            () => widget.onControl(b)),
    ];
    final hasOverflow = extras.isNotEmpty;

    return Container(
      color: primary,
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // When expanded the LOV buttons appear in rows ABOVE the fixed row.
          if (hasOverflow && _expanded)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 2,
                runSpacing: 6,
                children: extraBtns,
              ),
            ),
          // 3-dot handle toggles the expanded rows.
          if (hasOverflow)
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: const SizedBox(
                  height: 22,
                  child: Icon(Icons.more_horiz, color: Colors.white70, size: 22)),
            )
          else
            const SizedBox(height: 6),
          // Fixed bottom row: BACK + SEARCH left, SEND right. Collapsed, the LOV
          // buttons scroll in the middle; expanded, the middle is cleared.
          Row(
            children: [
              _btn(Icons.arrow_back, 'BACK', widget.onBack),
              _btn(Icons.search, 'SEARCH', widget.onSearch),
              Expanded(
                child: _expanded
                    ? const SizedBox.shrink()
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(mainAxisSize: MainAxisSize.min, children: extraBtns),
                      ),
              ),
              _btn(Icons.send, 'SEND', widget.onSend),
            ],
          ),
        ],
      ),
    );
  }
}
