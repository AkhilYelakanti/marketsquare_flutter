import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../orderentry/order_widgets.dart';
import 'backroom_controller.dart';

/// Port of native `ResetInventoryScreen`: clear one department or everything.
class ResetInventoryScreen extends ConsumerStatefulWidget {
  const ResetInventoryScreen({super.key});

  @override
  ConsumerState<ResetInventoryScreen> createState() => _State();
}

class _State extends ConsumerState<ResetInventoryScreen> {
  String? _dept;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final st = ref.watch(backroomControllerProvider);
    final ctrl = ref.read(backroomControllerProvider.notifier);

    ref.listen(backroomControllerProvider.select((s) => s.message), (_, m) {
      if (m != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
        ctrl.clearMessage();
      }
    });

    return Scaffold(
      appBar: orderAppBar(subtitle: 'RESET INVENTORY', height: 60),
      bottomNavigationBar: OrderBottomBar(onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Clear a department',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          if (st.departments.isEmpty)
            const Text('No departments configured.', style: TextStyle(color: Colors.grey))
          else
            DropdownButtonFormField<String>(
              initialValue: _dept,
              decoration: const InputDecoration(
                  labelText: 'Department', border: OutlineInputBorder(), isDense: true),
              items: [
                for (final d in st.departments) DropdownMenuItem(value: d, child: Text(d))
              ],
              onChanged: (v) => setState(() => _dept = v),
            ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _dept == null
                ? null
                : () => _confirm(context, 'Clear all items in $_dept?',
                    () => ctrl.clearByDepartment(_dept!)),
            icon: const Icon(Icons.delete_outline),
            label: const Text('CLEAR DEPARTMENT'),
            style: ElevatedButton.styleFrom(
                backgroundColor: primary, foregroundColor: Colors.white),
          ),
          const Divider(height: 36),
          const Text('Clear everything',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _confirm(context,
                'Clear ALL backroom inventory? This cannot be undone.', ctrl.clearAll),
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            label: const Text('CLEAR ALL', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirm(BuildContext context, String msg, VoidCallback onYes) {
    showDialog<void>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('Confirm'),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(dctx);
              onYes();
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
