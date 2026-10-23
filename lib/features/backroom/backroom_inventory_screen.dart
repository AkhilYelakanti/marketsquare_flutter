import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_routes.dart';
import '../orderentry/order_widgets.dart';

/// Port of native `BackroomInventoryScreen` landing menu.
class BackroomInventoryScreen extends StatelessWidget {
  const BackroomInventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final opts = [
      ('Update Inventory', Icons.add_box, Routes.backroomUpdate),
      ('View Pull List', Icons.list_alt, Routes.backroomPullList),
      ('Reset Inventory', Icons.delete_sweep, Routes.backroomReset),
    ];
    return Scaffold(
      appBar: orderAppBar(subtitle: 'BACKROOM INVENTORY', height: 60),
      bottomNavigationBar: OrderBottomBar(onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        children: [
          for (final (title, icon, route) in opts)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                color: const Color(0xFFE0E0E0),
                shape: const RoundedRectangleBorder(),
                child: InkWell(
                  onTap: () => context.push(route),
                  child: SizedBox(
                    height: 96,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: primary, width: 3)),
                          child: Icon(icon, color: primary, size: 28),
                        ),
                        const SizedBox(height: 6),
                        Text(title,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
