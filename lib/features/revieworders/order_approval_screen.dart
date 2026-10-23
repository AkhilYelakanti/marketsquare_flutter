import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_routes.dart';
import '../orderentry/order_widgets.dart';

/// Port of native `OrderApprovalScreen`: chooser between waiting and approved.
class OrderApprovalScreen extends StatelessWidget {
  const OrderApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: orderAppBar(subtitle: 'ORDER APPROVAL', height: 60),
      bottomNavigationBar: OrderBottomBar(onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        children: [
          _card(context, primary, 'Orders Waiting for Approval',
              'Review and approve pending orders', Icons.hourglass_top,
              '${Routes.approvalsList}?mode=WAITING'),
          const SizedBox(height: 10),
          _card(context, primary, 'Approved Orders',
              'View previously approved and sent orders', Icons.assignment_turned_in,
              '${Routes.approvalsList}?mode=APPROVED'),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, Color primary, String title, String subtitle,
      IconData icon, String route) {
    return Card(
      color: const Color(0xFFE0E0E0),
      shape: const RoundedRectangleBorder(),
      child: InkWell(
        onTap: () => context.push(route),
        child: SizedBox(
          height: 104,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                    shape: BoxShape.circle, border: Border.all(color: primary, width: 3)),
                child: Icon(icon, color: primary, size: 28),
              ),
              const SizedBox(height: 6),
              Text(title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(subtitle,
                  style: const TextStyle(color: Colors.black54, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}
