import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db/backroom_item.dart';
import '../orderentry/order_widgets.dart';
import 'backroom_controller.dart';

/// Port of native `ViewPullListScreen`: all backroom items grouped by
/// department; PULL removes one unit (deletes the row at 0).
class ViewPullListScreen extends ConsumerWidget {
  const ViewPullListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = Theme.of(context).colorScheme.primary;
    final st = ref.watch(backroomControllerProvider);
    final ctrl = ref.read(backroomControllerProvider.notifier);

    final byDept = <String, List<BackroomItem>>{};
    for (final it in st.allItems) {
      (byDept[it.department.isEmpty ? '—' : it.department] ??= []).add(it);
    }

    return Scaffold(
      appBar: orderAppBar(subtitle: 'PULL LIST', height: 60),
      bottomNavigationBar: OrderBottomBar(onBack: () => context.pop()),
      body: st.allItems.isEmpty
          ? const Center(
              child: Text('Backroom inventory is empty.',
                  style: TextStyle(color: Colors.grey)))
          : ListView(
              children: [
                for (final entry in byDept.entries) ...[
                  Container(
                    width: double.infinity,
                    color: const Color(0xFFEFEFEF),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Text(entry.key,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  for (final it in entry.value)
                    ListTile(
                      dense: true,
                      title:
                          Text(it.itemDescription.isEmpty ? it.itemCode : it.itemDescription),
                      subtitle: Text('# ${it.itemCode}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Qty ${it.quantity}',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () => ctrl.pullItem(it),
                            style: OutlinedButton.styleFrom(
                                foregroundColor: primary,
                                visualDensity: VisualDensity.compact),
                            child: const Text('PULL'),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
    );
  }
}
