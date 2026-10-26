import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/order_models.dart';
import '../../router/app_routes.dart';
import '../orderentry/order_widgets.dart';
import 'approvals_controller.dart';

/// Port of native `ApprovalsListScreen` (ORDERS FOR APPROVAL): a Dept/Date/
/// Conf#/Items/Cases/Est.$ table with a single-select checkbox per row. DELETE
/// SELECTED removes the checked order (with confirm); tapping a row confirms,
/// loads the order and continues to the send flow for approval.
class ApprovalsListScreen extends ConsumerStatefulWidget {
  final String mode;
  const ApprovalsListScreen({super.key, this.mode = 'WAITING'});

  @override
  ConsumerState<ApprovalsListScreen> createState() => _State();
}

class _State extends ConsumerState<ApprovalsListScreen> {
  bool _deleting = false;
  bool _retrieving = false;

  bool get _waiting => widget.mode.toUpperCase() != 'APPROVED';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(approvalsControllerProvider.notifier).load(_waiting));
  }

  String _summary(ApprovalOrderSummary o) =>
      '${o.department} - ${o.orderDate} - ${o.confirmationId} - '
      '${o.totalCaseQty} cases - \$${o.totalEstimateValue}';

  Future<void> _delete() async {
    final st = ref.read(approvalsControllerProvider);
    if (st.selectedIds.isEmpty) return;
    final o =
        st.orders.firstWhere((e) => e.confirmationId == st.selectedIds.first);
    final yes = await _confirm(
        'Confirm Order Deletion', 'Are you trying to delete the order:\n${_summary(o)}');
    if (yes != true || !mounted) return;
    setState(() => _deleting = true);
    final ok = await ref.read(approvalsControllerProvider.notifier).deleteSelected();
    if (!mounted) return;
    setState(() => _deleting = false);
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Order deleted.' : 'Delete failed.')));
  }

  Future<void> _approve(ApprovalOrderSummary o) async {
    final yes = await _confirm('Confirm Order Approval',
        'You are trying to approve the order:\n\n${_summary(o)}');
    if (yes != true || !mounted) return;
    setState(() => _retrieving = true);
    final id = await ref
        .read(approvalsControllerProvider.notifier)
        .loadOrderForEditing(o.confirmationId);
    if (!mounted) return;
    setState(() => _retrieving = false);
    if (id != -1) {
      // Native: opens the order for review/approval, then the send flow
      // preselects it (green) with APPROVED SEND SELECTED.
      context.push('${Routes.sendOrders}?currentOrderId=$id');
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Could not open order.')));
    }
  }

  Future<void> _openApproved(ApprovalOrderSummary o) async {
    await ref.read(approvalsControllerProvider.notifier).loadApprovedDetail(o.confirmationId);
    if (!mounted) return;
    context.push('${Routes.approvalOrderDetail}?confirmId=${o.confirmationId}');
  }

  Future<bool?> _confirm(String title, String body) => showDialog<bool>(
        context: context,
        builder: (dctx) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dctx, false), child: const Text('No')),
            TextButton(
                onPressed: () => Navigator.pop(dctx, true), child: const Text('Yes')),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final st = ref.watch(approvalsControllerProvider);

    return Scaffold(
      appBar: orderAppBar(subtitle: 'ORDERS FOR APPROVAL', height: 64),
      bottomNavigationBar: OrderBottomBar(
        onBack: () => context.pop(),
        acceptLabel: _waiting && st.selectedIds.isNotEmpty ? 'DELETE\nSELECTED' : null,
        onAccept: _waiting && st.selectedIds.isNotEmpty ? _delete : null,
      ),
      body: Stack(
        children: [
          switch (st.loadState) {
            ApprovalLoad.loading =>
              const Center(child: CircularProgressIndicator()),
            ApprovalLoad.error => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                      'Could not load approvals.\nCheck connection + endpoint config.',
                      textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                ),
              ),
            ApprovalLoad.idle => _content(primary, st),
          },
          if (_deleting) _overlay('deleting selected...'),
          if (_retrieving) _overlay('retrieving details'),
        ],
      ),
    );
  }

  Widget _content(Color primary, ApprovalsState st) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Text(_waiting ? 'Orders Waiting for Approval' : 'Approved Orders',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        if (_waiting)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text('Please tap on an order below to review, edit, and approve.',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
        const SizedBox(height: 4),
        _headerRow(),
        Expanded(
          child: st.orders.isEmpty
              ? const Center(child: Text('No orders.', style: TextStyle(color: Colors.grey)))
              : ListView.separated(
                  itemCount: st.orders.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: Color(0xFFCCCCCC)),
                  itemBuilder: (_, i) => _OrderRow(
                    order: st.orders[i],
                    selected: st.selectedIds.contains(st.orders[i].confirmationId),
                    waiting: _waiting,
                    onToggle: () => ref
                        .read(approvalsControllerProvider.notifier)
                        .toggleSelection(st.orders[i].confirmationId),
                    onOpen: () =>
                        _waiting ? _approve(st.orders[i]) : _openApproved(st.orders[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _headerRow() => Container(
        color: const Color(0xFFBFE3EE),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: const [
            SizedBox(width: 40),
            _HCell('Dept', 2),
            _HCell('Date', 3),
            _HCell('Conf #', 3),
            _HCell('Items', 2),
            _HCell('Cases', 2),
            _HCell('Est. \$', 2),
          ],
        ),
      );

  Widget _overlay(String label) => Positioned.fill(
        child: ColoredBox(
          color: Colors.black54,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                    width: 64,
                    height: 64,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 5)),
                const SizedBox(height: 18),
                Text(label,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('please wait...',
                    style: TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
          ),
        ),
      );
}

class _HCell extends StatelessWidget {
  final String text;
  final int flex;
  const _HCell(this.text, this.flex);
  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child: Text(text,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      );
}

class _OrderRow extends StatelessWidget {
  final ApprovalOrderSummary order;
  final bool selected;
  final bool waiting;
  final VoidCallback onToggle;
  final VoidCallback onOpen;
  const _OrderRow({
    required this.order,
    required this.selected,
    required this.waiting,
    required this.onToggle,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    Widget cell(String t, int flex) => Expanded(
        flex: flex,
        child: Text(t, style: const TextStyle(fontSize: 14, color: Colors.black87)));

    return InkWell(
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: waiting
                  ? GestureDetector(
                      onTap: onToggle,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: selected ? primary : Colors.white,
                          border: Border.all(color: primary, width: 2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: selected
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    )
                  : const Icon(Icons.chevron_right),
            ),
            cell(order.department, 2),
            cell(order.orderDate, 3),
            cell(order.confirmationId, 3),
            cell(order.totalItems, 2),
            cell(order.totalCaseQty, 2),
            cell('\$${order.totalEstimateValue}', 2),
          ],
        ),
      ),
    );
  }
}
