import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/order_models.dart';
import '../orderentry/order_widgets.dart';
import 'approvals_controller.dart';

/// Port of native `ApprovalOrderDetailScreen`: read-only approved order,
/// items grouped by department.
class ApprovalOrderDetailScreen extends ConsumerStatefulWidget {
  final String confirmId;
  const ApprovalOrderDetailScreen({super.key, this.confirmId = ''});

  @override
  ConsumerState<ApprovalOrderDetailScreen> createState() => _State();
}

class _State extends ConsumerState<ApprovalOrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    final st = ref.read(approvalsControllerProvider);
    if (st.approvedDetail == null && widget.confirmId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) =>
          ref.read(approvalsControllerProvider.notifier).loadApprovedDetail(widget.confirmId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(approvalsControllerProvider);
    final order = st.approvedDetail;
    final header = order?.header;

    // Group details by department.
    final byDept = <String, List<ApiOrderDetail>>{};
    for (final d in order?.details ?? const <ApiOrderDetail>[]) {
      (byDept[d.storeDepartment.isEmpty ? '—' : d.storeDepartment] ??= []).add(d);
    }

    return Scaffold(
      appBar: orderAppBar(subtitle: 'APPROVED ORDER', height: 60),
      bottomNavigationBar: OrderBottomBar(onBack: () => context.pop()),
      body: st.loadingDetail
          ? const Center(child: CircularProgressIndicator())
          : order == null
              ? const Center(
                  child: Text('No detail available.', style: TextStyle(color: Colors.grey)))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (header != null) _HeaderCard(header: header, confirmId: widget.confirmId),
                    const SizedBox(height: 12),
                    for (final entry in byDept.entries) ...[
                      Container(
                        width: double.infinity,
                        color: const Color(0xFFEFEFEF),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Text(entry.key,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      for (final d in entry.value)
                        ListTile(
                          dense: true,
                          title: Text(d.itemDescription.isEmpty ? d.itemNumber : d.itemDescription),
                          subtitle: Text('# ${d.itemNumber}'),
                          trailing: Text('Qty ${d.quantity}',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ],
                ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final ApiOrderHeader header;
  final String confirmId;
  const _HeaderCard({required this.header, required this.confirmId});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        border: Border.all(color: const Color(0xFFDDDDDD)),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(header.requestType.isEmpty ? 'ORDER' : header.requestType,
              style: TextStyle(fontWeight: FontWeight.bold, color: primary, fontSize: 15)),
          if (confirmId.isNotEmpty) Text('Confirmation #: $confirmId'),
          if (header.custPoNumber.isNotEmpty) Text('PO: ${header.custPoNumber}'),
          if (header.storePartition.isNotEmpty) Text('Partition: ${header.storePartition}'),
          if (header.requestedDeliveryDate.isNotEmpty)
            Text('Delivery: ${header.requestedDeliveryDate}'),
          if (header.totalEstimateValue.isNotEmpty)
            Text('Est Value: \$${header.totalEstimateValue}'),
        ],
      ),
    );
  }
}
