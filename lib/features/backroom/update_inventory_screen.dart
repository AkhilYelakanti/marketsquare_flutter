import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/scanner_sheet.dart';
import '../orderentry/order_widgets.dart';
import 'backroom_controller.dart';

/// Port of native `UpdateInventoryScreen`: pick department, enter/scan an item
/// code + qty, ADD. Shows the current department's items.
class UpdateInventoryScreen extends ConsumerStatefulWidget {
  const UpdateInventoryScreen({super.key});

  @override
  ConsumerState<UpdateInventoryScreen> createState() => _State();
}

class _State extends ConsumerState<UpdateInventoryScreen> {
  final _dept = TextEditingController();
  final _code = TextEditingController();
  final _desc = TextEditingController();
  int _qty = 1;

  @override
  void dispose() {
    _dept.dispose();
    _code.dispose();
    _desc.dispose();
    super.dispose();
  }

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
      appBar: orderAppBar(subtitle: 'UPDATE INVENTORY', height: 60),
      bottomNavigationBar: OrderBottomBar(onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _deptField(st.departments),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _code,
                  decoration: const InputDecoration(
                      labelText: 'Item Code', border: OutlineInputBorder(), isDense: true),
                ),
              ),
              IconButton(
                onPressed: () async {
                  final c = await ScannerSheet.scan(context);
                  if (c != null) setState(() => _code.text = c);
                },
                icon: Icon(Icons.qr_code_scanner, color: primary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _desc,
            decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
                isDense: true),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('Qty:', style: TextStyle(fontWeight: FontWeight.bold)),
              IconButton(
                  onPressed: () => setState(() => _qty = (_qty - 1).clamp(1, 9999)),
                  icon: Icon(Icons.remove_circle_outline, color: primary)),
              Text('$_qty', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              IconButton(
                  onPressed: () => setState(() => _qty++),
                  icon: Icon(Icons.add_circle_outline, color: primary)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () async {
                  final ok = await ctrl.addOrUpdateItem(
                      _dept.text.trim(), _code.text.trim(), _desc.text.trim(), _qty);
                  if (ok) {
                    setState(() {
                      _code.clear();
                      _desc.clear();
                      _qty = 1;
                    });
                    ctrl.selectDepartment(_dept.text.trim());
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('ADD'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: primary, foregroundColor: Colors.white),
              ),
            ],
          ),
          const Divider(height: 28),
          Text('Items in ${_dept.text.trim().isEmpty ? '(select dept)' : _dept.text.trim()}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          if (st.itemsByDepartment.isEmpty)
            const Text('No items yet.', style: TextStyle(color: Colors.grey))
          else
            for (final it in st.itemsByDepartment)
              ListTile(
                dense: true,
                title: Text(it.itemDescription.isEmpty ? it.itemCode : it.itemDescription),
                subtitle: Text('# ${it.itemCode}'),
                trailing: Text('Qty ${it.quantity}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
        ],
      ),
    );
  }

  Widget _deptField(List<String> departments) {
    if (departments.isEmpty) {
      return TextField(
        controller: _dept,
        onChanged: (v) => ref.read(backroomControllerProvider.notifier).selectDepartment(v.trim()),
        decoration: const InputDecoration(
            labelText: 'Department', border: OutlineInputBorder(), isDense: true),
      );
    }
    final value = _dept.text.isEmpty ? null : _dept.text;
    return DropdownButtonFormField<String>(
      initialValue: departments.contains(value) ? value : null,
      decoration: const InputDecoration(
          labelText: 'Department', border: OutlineInputBorder(), isDense: true),
      items: [for (final d in departments) DropdownMenuItem(value: d, child: Text(d))],
      onChanged: (v) {
        if (v == null) return;
        setState(() => _dept.text = v);
        ref.read(backroomControllerProvider.notifier).selectDepartment(v);
      },
    );
  }
}
