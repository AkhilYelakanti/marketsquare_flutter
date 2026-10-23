import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_routes.dart';
import '../orderentry/order_widgets.dart';

class _Opt {
  final String title;
  final IconData icon;
  final String route;
  const _Opt(this.title, this.icon, this.route);
}

/// Port of native `ReviewOrdersScreen` landing menu. (Approval/invoice options
/// are gated by LOV1 flags in native; shown here while those flags default off.)
class ReviewOrdersScreen extends StatelessWidget {
  const ReviewOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    const options = [
      _Opt('View Device Orders', Icons.assignment, Routes.viewDeviceOrders),
      _Opt('View All Previous Store Orders', Icons.assignment_late,
          Routes.viewStoreOrdersSelect),
      _Opt('Order Approval', Icons.thumb_up, Routes.orderApproval),
      _Opt('View Invoices', Icons.description, Routes.invoiceList),
      _Opt('View Invoices - PDF', Icons.picture_as_pdf, Routes.invoicePdfList),
    ];

    return Scaffold(
      appBar: orderAppBar(subtitle: 'REVIEW ORDERS', height: 64),
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
          height: 104,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: primary, width: 3),
                ),
                child: Icon(opt.icon, color: primary, size: 30),
              ),
              const SizedBox(height: 6),
              Text(opt.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}
