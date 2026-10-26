import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/session/session_providers.dart';
import '../../router/app_routes.dart';
import '../orderentry/order_widgets.dart';

class _Opt {
  final String title;
  final IconData icon;
  final String route;
  const _Opt(this.title, this.icon, this.route);
}

/// Port of native `ReviewOrdersScreen` landing menu. View Device Orders and
/// View All Previous Store Orders always show; Order Approval / View Invoices /
/// View Invoices-PDF are gated by LOV1 flags (orderApprovalView,
/// enableViewInvoice, displayInvoicePDF).
class ReviewOrdersScreen extends ConsumerWidget {
  const ReviewOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = Theme.of(context).colorScheme.primary;
    final sm = ref.watch(sessionManagerProvider);

    final options = <_Opt>[
      const _Opt('View Device Orders', Icons.assignment, Routes.viewDeviceOrders),
      const _Opt('View All Previous Store Orders', Icons.assignment_late,
          Routes.viewStoreOrdersSelect),
      if (sm.isOrderApprovalEnabled())
        const _Opt('Order Approval', Icons.thumb_up,
            '${Routes.approvalsList}?mode=WAITING'),
      if (sm.isViewInvoiceEnabled())
        const _Opt('View Invoices', Icons.description, Routes.invoiceList),
      if (sm.isInvoicePdfEnabled())
        const _Opt('View Invoices - PDF', Icons.picture_as_pdf, Routes.invoicePdfList),
    ];

    return Scaffold(
      appBar: orderAppBar(subtitle: 'REVIEW ORDERS', height: 70),
      bottomNavigationBar: OrderBottomBar(onBack: () => context.pop()),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _OptCard(opt: options[i], primary: primary),
      ),
    );
  }
}

class _OptCard extends StatelessWidget {
  final _Opt opt;
  final Color primary;
  const _OptCard({required this.opt, required this.primary});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFE0E0E0),
      shape: const RoundedRectangleBorder(),
      child: InkWell(
        onTap: () => context.push(opt.route),
        child: SizedBox(
          height: 108,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: primary, width: 3),
                ),
                alignment: Alignment.center,
                child: Icon(opt.icon, color: primary, size: 32),
              ),
              const SizedBox(height: 6),
              Text(opt.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}
