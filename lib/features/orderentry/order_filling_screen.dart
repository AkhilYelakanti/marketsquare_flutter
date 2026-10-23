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
    final ctrl = ref.read(orderEntryControllerProvider.notifier);
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
        onScan: () => _scanAdd(context, ref),
        onSend: () => _send(context, ref),
        extra: st.controlButtonsForCurrentType,
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
                    itemBuilder: (_, i) => _LineRow(
                      line: lines[i],
                      primary: primary,
                      onInc: () => ctrl.commitItem(lines[i].item,
                          '${(int.tryParse(lines[i].qty) ?? 0) + 1}'),
                      onDec: () {
                        final n = (int.tryParse(lines[i].qty) ?? 0) - 1;
                        ctrl.commitItem(lines[i].item, n <= 0 ? '0' : '$n');
                      },
                      onRemove: () => ctrl.removeLine(lines[i].item),
                    ),
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
          for (final t in st.config.totalFields)
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

class _LineRow extends StatelessWidget {
  final OrderLine line;
  final Color primary;
  final VoidCallback onInc;
  final VoidCallback onDec;
  final VoidCallback onRemove;
  const _LineRow({
    required this.line,
    required this.primary,
    required this.onInc,
    required this.onDec,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final number = line.item[ItemRepository.colItem] ?? '';
    final desc = line.item[ItemRepository.colDesc] ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(desc.isEmpty ? number : desc,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Text('# $number',
                    style: const TextStyle(fontSize: 11, color: Colors.black54)),
              ],
            ),
          ),
          IconButton(
              onPressed: onDec,
              icon: Icon(Icons.remove_circle_outline, color: primary),
              visualDensity: VisualDensity.compact),
          Text(line.qty, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          IconButton(
              onPressed: onInc,
              icon: Icon(Icons.add_circle_outline, color: primary),
              visualDensity: VisualDensity.compact),
          IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline, color: Colors.black38),
              visualDensity: VisualDensity.compact),
        ],
      ),
    );
  }
}

class _BottomControls extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onSearch;
  final VoidCallback onScan;
  final VoidCallback onSend;
  final List<OrderControlButton> extra;
  const _BottomControls({
    required this.onBack,
    required this.onSearch,
    required this.onScan,
    required this.onSend,
    required this.extra,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    Widget btn(IconData icon, String label, VoidCallback onTap) => InkWell(
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
            ],
          ),
        );
    return Container(
      color: primary,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          btn(Icons.arrow_back, 'BACK', onBack),
          btn(Icons.search, 'SEARCH', onSearch),
          btn(Icons.qr_code_scanner, 'SCAN', onScan),
          btn(Icons.send, 'SEND', onSend),
        ],
      ),
    );
  }
}
