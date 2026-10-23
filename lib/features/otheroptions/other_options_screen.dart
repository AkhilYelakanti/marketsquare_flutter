import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_routes.dart';
import '../orderentry/order_widgets.dart';

/// Minimal `OtherOptionsScreen`: entry point for Backroom Inventory (the other
/// native options — debug/operational guide/etc. — remain follow-ups).
class OtherOptionsScreen extends StatelessWidget {
  const OtherOptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: orderAppBar(subtitle: 'OTHER OPTIONS', height: 60),
      bottomNavigationBar: OrderBottomBar(onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        children: [
          Card(
            color: const Color(0xFFE0E0E0),
            shape: const RoundedRectangleBorder(),
            child: InkWell(
              onTap: () => context.push(Routes.backroomInventory),
              child: SizedBox(
                height: 96,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle, border: Border.all(color: primary, width: 3)),
                      child: Icon(Icons.inventory_2, color: primary, size: 28),
                    ),
                    const SizedBox(height: 6),
                    const Text('Backroom Inventory',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
