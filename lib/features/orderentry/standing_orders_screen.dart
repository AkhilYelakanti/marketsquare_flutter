import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_routes.dart';
import 'order_widgets.dart';
import 'standing_orders_controller.dart';

/// Port of native `StandingOrdersScreen`: list saved templates; start one
/// (loads its lines into the order editor), delete, or save the current order
/// as a new template.
class StandingOrdersScreen extends ConsumerStatefulWidget {
  const StandingOrdersScreen({super.key});

  @override
  ConsumerState<StandingOrdersScreen> createState() => _State();
}

class _State extends ConsumerState<StandingOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(standingOrdersControllerProvider.notifier).loadNames());
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final st = ref.watch(standingOrdersControllerProvider);
    final ctrl = ref.read(standingOrdersControllerProvider.notifier);

    ref.listen(standingOrdersControllerProvider.select((s) => s.message), (_, m) {
      if (m != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
        ctrl.clearMessage();
      }
    });

    return Scaffold(
      appBar: orderAppBar(subtitle: 'STANDING ORDERS', height: 60),
      bottomNavigationBar: OrderBottomBar(
        onBack: () => context.pop(),
        acceptLabel: 'SAVE CURRENT',
        onAccept: () => _saveDialog(ctrl),
      ),
      body: st.loading
          ? const Center(child: CircularProgressIndicator())
          : st.names.isEmpty
              ? const Center(
                  child: Text('No saved templates.', style: TextStyle(color: Colors.grey)))
              : ListView.separated(
                  itemCount: st.names.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  itemBuilder: (_, i) {
                    final name = st.names[i];
                    return ListTile(
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      leading: Icon(Icons.bookmark, color: primary),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () async {
                              final ok = await ctrl.startFromTemplate(name);
                              if (ok && context.mounted) context.push(Routes.orderFilling);
                            },
                            child: const Text('START'),
                          ),
                          IconButton(
                            onPressed: () => _confirmDelete(ctrl, name),
                            icon: const Icon(Icons.delete_outline, color: Colors.black38),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  void _saveDialog(StandingOrdersController ctrl) {
    final c = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('Save as Template'),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Template name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dctx), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              Navigator.pop(dctx);
              if (c.text.trim().isNotEmpty) ctrl.saveCurrentAsTemplate(c.text.trim());
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(StandingOrdersController ctrl, String name) {
    showDialog<void>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('Delete Template'),
        content: Text('Delete "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(dctx);
              ctrl.deleteTemplate(name);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
