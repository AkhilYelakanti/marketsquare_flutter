import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/order_models.dart';
import '../../router/app_routes.dart';
import '../orderentry/order_widgets.dart';
import 'approvals_controller.dart';

/// Port of native `ApprovalsListScreen` (WAITING / APPROVED). Single-select;
/// WAITING supports delete + open-for-editing, APPROVED opens a read-only detail.
class ApprovalsListScreen extends ConsumerStatefulWidget {
  final String mode;
  const ApprovalsListScreen({super.key, this.mode = 'WAITING'});

  @override
  ConsumerState<ApprovalsListScreen> createState() => _State();
}

class _State extends ConsumerState<ApprovalsListScreen> {
  bool get _waiting => widget.mode.toUpperCase() != 'APPROVED';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(approvalsControllerProvider.notifier).load(_waiting));
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(approvalsControllerProvider);
    final ctrl = ref.read(approvalsControllerProvider.notifier);
    final title = _waiting ? 'ORDERS WAITING' : 'APPROVED ORDERS';

    return Scaffold(
      appBar: orderAppBar(subtitle: title, height: 64),
      bottomNavigationBar: OrderBottomBar(
        onBack: () => context.pop(),
        acceptLabel: _waiting && st.selectedIds.isNotEmpty ? 'DELETE' : null,
        onAccept: _waiting && st.selectedIds.isNotEmpty
            ? () async {
                final ok = await ctrl.deleteSelected();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(ok ? 'Deleted.' : 'Delete failed.')));
                }
              }
            : null,
      ),
      body: switch (st.loadState) {
        ApprovalLoad.loading => const Center(child: CircularProgressIndicator()),
        ApprovalLoad.error => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Could not load approvals.\nCheck connection + endpoint config.',
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            ),
          ),
        ApprovalLoad.idle => st.orders.isEmpty
            ? const Center(
                child: Text('No orders.', style: TextStyle(color: Colors.grey)))
            : ListView.separated(
                itemCount: st.orders.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: Color(0xFFDDDDDD)),
                itemBuilder: (_, i) => _Row(
                  order: st.orders[i],
                  selected: st.selectedIds.contains(st.orders[i].confirmationId),
                  waiting: _waiting,
                  onToggle: () => ctrl.toggleSelection(st.orders[i].confirmationId),
                  onOpen: () => _open(st.orders[i]),
                ),
              ),
      },
    );
  }

  Future<void> _open(ApprovalOrderSummary o) async {
    final ctrl = ref.read(approvalsControllerProvider.notifier);
    if (_waiting) {
      final id = await ctrl.loadOrderForEditing(o.confirmationId);
      if (!mounted) return;
      if (id != -1) {
        // Fetched order saved locally as UNSENT; open it in Send Orders.
        // (Loading it back into the live order editor is a follow-up.)
        context.push('${Routes.sendOrders}?currentOrderId=$id');
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Could not open order.')));
      }
    } else {
      await ctrl.loadApprovedDetail(o.confirmationId);
      if (!mounted) return;
      context.push('${Routes.approvalOrderDetail}?confirmId=${o.confirmationId}');
    }
  }
}

class _Row extends StatelessWidget {
  final ApprovalOrderSummary order;
  final bool selected;
  final bool waiting;
  final VoidCallback onToggle;
  final VoidCallback onOpen;
  const _Row({
    required this.order,
    required this.selected,
    required this.waiting,
    required this.onToggle,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onOpen,
      child: Container(
        color: selected ? const Color(0xFFE8F5E9) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Conf #${order.confirmationId}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: primary)),
                  if (order.department.isNotEmpty)
                    Text('Dept: ${order.department}',
                        style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  Text(
                      'Items ${order.totalItems} · Qty ${order.totalCaseQty} · \$${order.totalEstimateValue}',
                      style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  if (order.orderDate.isNotEmpty)
                    Text(order.orderDate,
                        style: const TextStyle(fontSize: 11, color: Colors.black38)),
                ],
              ),
            ),
            if (waiting)
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? primary : Colors.transparent,
                    border: Border.all(color: primary, width: 2),
                  ),
                  child: selected
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
              )
            else
              const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
