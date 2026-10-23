import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'order_entry_controller.dart';
import 'order_widgets.dart';

/// Port of native `SelectPartitionScreen`: searchable partition list; tap sets
/// PARTITION and pops back.
class SelectPartitionScreen extends ConsumerStatefulWidget {
  const SelectPartitionScreen({super.key});

  @override
  ConsumerState<SelectPartitionScreen> createState() => _State();
}

class _State extends ConsumerState<SelectPartitionScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final st = ref.watch(orderEntryControllerProvider);
    final ctrl = ref.read(orderEntryControllerProvider.notifier);

    final q = _search.trim().toLowerCase();
    final filtered = q.isEmpty
        ? st.config.partitions
        : st.config.partitions.where((p) => p.toLowerCase().contains(q)).toList();

    return Scaffold(
      appBar: orderAppBar(
        subtitle: 'SELECT A PARTITION',
        third: '${filtered.length} partition(s)',
        height: 84,
      ),
      bottomNavigationBar: OrderBottomBar(onBack: () => context.pop()),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Filter partitions',
                prefixIcon: Icon(Icons.search, color: primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 0.5, color: Color(0xFFEEEEEE)),
              itemBuilder: (_, i) {
                final p = filtered[i];
                final selected = st.selectedPartition == p;
                return InkWell(
                  onTap: () {
                    ctrl.setPartition(p);
                    context.pop();
                  },
                  child: Container(
                    color: selected ? primary.withValues(alpha: 0.06) : null,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selected ? primary : Colors.transparent,
                            border: Border.all(
                                color: selected ? primary : const Color(0xFFCCCCCC),
                                width: selected ? 2 : 1),
                          ),
                          child: selected
                              ? const Icon(Icons.check, color: Colors.white, size: 18)
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Text(p,
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight:
                                    selected ? FontWeight.bold : FontWeight.normal,
                                color: selected ? primary : Colors.black)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
