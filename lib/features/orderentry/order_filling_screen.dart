import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db/item_repository.dart';
import '../../data/models/order_models.dart';
import '../../router/app_routes.dart';
import '../../widgets/hardware_scan_listener.dart';
import '../../widgets/scanner_sheet.dart';
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
    final lines = st.orderLines.reversed.toList(); // newest first (native default)

    return Scaffold(
      appBar: orderAppBar(
        subtitle: st.selectedOrderType ?? 'ORDER',
        third: st.selectedCustomer != null ? 'Store: ${st.selectedCustomer!.storeId}' : null,
        height: 80,
      ),
      bottomNavigationBar: _BottomControls(
        onBack: () => context.pop(),
        onSearch: () => context.push(Routes.orderItemSearch),
        onSend: () => _send(context, ref),
        extra: st.controlButtonsForCurrentType,
        onControl: (b) => _handleControl(context, ref, b),
      ),
      body: Column(
        children: [
          _HeaderSummary(primary: primary),
          _TotalsBar(primary: primary),
          const Divider(height: 1),
          Expanded(
            child: lines.isEmpty
                ? const Center(
                    child: Text('No items yet.\nUse SEARCH or SCAN to add items.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey)))
                : ListView.separated(
                    itemCount: lines.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 0.5, color: Color(0xFFEEEEEE)),
                    // Rich config-driven tile (image, cost fields, qty stepper)
                    // from the LOV tile config for this order type.
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
    final matches = await repo.queryByExactCode(code);
    if (!context.mounted) return;
    if (matches.isEmpty) {
      // Catalog miss — add a minimal line so scanned/keyed codes still work.
      ctrl.commitItem({ItemRepository.colItem: code, ItemRepository.colDesc: 'Item $code'}, '1');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added $code (not in catalog)')));
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

class _HeaderSummary extends ConsumerWidget {
  final Color primary;
  const _HeaderSummary({required this.primary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(orderEntryControllerProvider);
    return Container(
      color: const Color(0xFFF5F5F5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PO: ${st.poNumber}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                if (st.deliveryDate.isNotEmpty)
                  Text('Delivery: ${st.deliveryDate}',
                      style: const TextStyle(fontSize: 11, color: Colors.black54)),
              ],
            ),
          ),
          InkWell(
            onTap: () => context.push(Routes.selectPartition),
            child: Row(
              children: [
                Text(st.selectedPartition,
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold, color: primary)),
                Icon(Icons.arrow_drop_down, color: primary),
              ],
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

class _BottomControls extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    Widget btn(IconData icon, String label, VoidCallback onTap) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
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

    // Base actions + the LOV1-driven control buttons for this order type.
    // Dedupe config buttons that duplicate a base action.
    const baseKeys = {'BACK', 'SEARCH', 'SEND'};
    final extras =
        extra.where((b) => !baseKeys.contains(b.key.toUpperCase())).toList();
    final buttons = <Widget>[
      btn(Icons.arrow_back, 'BACK', onBack),
      btn(Icons.search, 'SEARCH', onSearch),
      for (final b in extras)
        btn(_iconFor(b), b.label.toUpperCase(), () => onControl(b)),
      btn(Icons.send, 'SEND', onSend),
    ];

    return Container(
      color: primary,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(mainAxisSize: MainAxisSize.min, children: buttons),
      ),
    );
  }
}
