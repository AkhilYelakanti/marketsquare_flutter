import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_routes.dart';
import 'order_config.dart';
import 'order_entry_controller.dart';
import 'order_widgets.dart';

/// Port of native `SelectOrderTypeScreen`: 2-col grid of request types.
class SelectOrderTypeScreen extends ConsumerWidget {
  const SelectOrderTypeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = Theme.of(context).colorScheme.primary;
    final st = ref.watch(orderEntryControllerProvider);
    final ctrl = ref.read(orderEntryControllerProvider.notifier);

    return Scaffold(
      appBar: orderAppBar(
        subtitle: 'SELECT ORDER TYPE',
        third: st.selectedCustomer != null ? 'Store: ${st.selectedCustomer!.storeId}' : null,
        height: 80,
      ),
      bottomNavigationBar: OrderBottomBar(onBack: () => context.pop()),
      body: !st.configLoaded
          ? const Center(child: CircularProgressIndicator())
          : GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(12),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: [
                for (final type in st.config.requestTypes)
                  _OrderTypeButton(
                    label: type.replaceAll('_', ' '),
                    primary: primary,
                    onTap: () {
                      ctrl.selectOrderType(type);
                      if (normalizeTypeKey(type) == 'STANDING_ORDER') {
                        context.push(Routes.standingOrders);
                      } else {
                        context.push(Routes.orderHeader);
                      }
                    },
                  ),
              ],
            ),
    );
  }
}

class _OrderTypeButton extends StatelessWidget {
  final String label;
  final Color primary;
  final VoidCallback onTap;
  const _OrderTypeButton(
      {required this.label, required this.primary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: primary.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_iconFor(label), size: 38, color: primary),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
              child: Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold, color: primary)),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _iconFor(String label) {
    final u = label.toUpperCase();
    if (u.contains('ITEM')) return Icons.add_shopping_cart;
    if (u.contains('AD')) return Icons.newspaper;
    if (u.contains('PRICE')) return Icons.sell;
    if (u.contains('TAG')) return Icons.sell_outlined;
    if (u.contains('TOBACCO')) return Icons.smoking_rooms;
    if (u.contains('TPR')) return Icons.auto_awesome;
    if (u.contains('DEAL')) return Icons.local_offer;
    if (u.contains('STANDING')) return Icons.bookmark;
    return Icons.add_shopping_cart;
  }
}
