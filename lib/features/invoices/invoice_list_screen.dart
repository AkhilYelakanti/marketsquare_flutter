import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_routes.dart';
import '../orderentry/order_widgets.dart';
import 'invoices_controller.dart';

/// Port of native `InvoiceListScreen`: date-range + invoice# filters → list.
class InvoiceListScreen extends ConsumerStatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  ConsumerState<InvoiceListScreen> createState() => _State();
}

class _State extends ConsumerState<InvoiceListScreen> {
  String _from = '';
  String _to = '';
  final _invoiceCtl = TextEditingController();

  @override
  void dispose() {
    _invoiceCtl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool from) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
    );
    if (picked == null) return;
    String two(int n) => n.toString().padLeft(2, '0');
    final s = '${two(picked.month)}/${two(picked.day)}/${picked.year}';
    setState(() => from ? _from = s : _to = s);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final st = ref.watch(invoicesControllerProvider);
    final ctrl = ref.read(invoicesControllerProvider.notifier);

    return Scaffold(
      appBar: orderAppBar(subtitle: 'INVOICES', height: 60),
      bottomNavigationBar: OrderBottomBar(onBack: () => context.pop()),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(children: [
                  Expanded(child: _dateChip('From', _from, () => _pickDate(true), primary)),
                  const SizedBox(width: 8),
                  Expanded(child: _dateChip('To', _to, () => _pickDate(false), primary)),
                ]),
                const SizedBox(height: 8),
                TextField(
                  controller: _invoiceCtl,
                  decoration: const InputDecoration(
                    labelText: 'Invoice # (optional)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: st.loadingList
                        ? null
                        : () => ctrl.fetchList(
                            fromDate: _from, toDate: _to, invoiceNumber: _invoiceCtl.text),
                    icon: const Icon(Icons.search),
                    label: const Text('SEARCH'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: primary, foregroundColor: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _results(st, primary)),
        ],
      ),
    );
  }

  Widget _results(InvoicesState st, Color primary) {
    if (st.loadingList) return const Center(child: CircularProgressIndicator());
    if (st.listError.isNotEmpty) {
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(st.listError,
                  textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey))));
    }
    if (st.list.isEmpty) {
      return const _Hint('Set a date range and press SEARCH.');
    }
    return ListView.separated(
      itemCount: st.list.length,
      separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFEEEEEE)),
      itemBuilder: (_, i) {
        final inv = st.list[i];
        return ListTile(
          title: Text('Invoice #${inv.invoiceNumber}',
              style: TextStyle(fontWeight: FontWeight.bold, color: primary)),
          subtitle: Text(
              '${inv.invoiceDate}${inv.department.isNotEmpty ? '  •  ${inv.department}' : ''}'),
          trailing: Text('\$${inv.invoiceAmount}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          onTap: () => context.push('${Routes.invoiceDetail}?invoiceNumber=${inv.invoiceNumber}'),
        );
      },
    );
  }

  Widget _dateChip(String label, String value, VoidCallback onTap, Color primary) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
        child: Row(
          children: [
            Expanded(child: Text(value.isEmpty ? label : value)),
            Icon(Icons.calendar_today, size: 16, color: primary),
          ],
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  final String text;
  const _Hint(this.text);
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(text,
              textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey))));
}
