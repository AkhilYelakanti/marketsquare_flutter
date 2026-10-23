import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/order_models.dart';
import '../../router/app_routes.dart';
import 'order_entry_controller.dart';
import 'order_widgets.dart';

/// Port of native `OrderHeaderScreen`: dynamic form of tappable chips driven by
/// the order type's field config; NEW validates then opens Order Filling.
class OrderHeaderScreen extends ConsumerStatefulWidget {
  const OrderHeaderScreen({super.key});

  @override
  ConsumerState<OrderHeaderScreen> createState() => _OrderHeaderScreenState();
}

class _OrderHeaderScreenState extends ConsumerState<OrderHeaderScreen> {
  List<String> _errors = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = ref.read(orderEntryControllerProvider.notifier);
      final st = ref.read(orderEntryControllerProvider);
      if (st.deliveryDate.isEmpty) {
        final d = DateTime.now();
        String two(int n) => n.toString().padLeft(2, '0');
        ctrl.setFieldValue('DELIVERY_DATE', '${two(d.month)}/${two(d.day)}/${d.year}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(orderEntryControllerProvider);
    final ctrl = ref.read(orderEntryControllerProvider.notifier);
    final type = st.selectedOrderType ?? 'ORDER';
    final rows = ctrl.fieldsForOrderType(type);

    return Scaffold(
      appBar: orderAppBar(
        subtitle: type,
        third: st.selectedCustomer != null ? 'Store: ${st.selectedCustomer!.storeId}' : null,
        height: 80,
      ),
      bottomNavigationBar: OrderBottomBar(
        onBack: () => context.pop(),
        acceptLabel: 'NEW',
        onAccept: () {
          final errs = ctrl.validateHeader();
          if (errs.isNotEmpty) {
            setState(() => _errors = errs);
            return;
          }
          setState(() => _errors = []);
          context.push(Routes.orderFilling);
        },
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          if (_errors.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _errors
                    .map((e) => Text(e,
                        style: const TextStyle(color: Color(0xFFC62828), fontSize: 13)))
                    .toList(),
              ),
            ),
          for (final row in rows) ...[
            _FieldRowWidget(
              row: row,
              value: st.headerValues[row.config.fieldKey] ?? '',
              onEdit: () => _editField(context, ctrl, st, row),
            ),
            const Divider(height: 0.5, color: Colors.black12),
          ],
        ],
      ),
    );
  }

  Future<void> _editField(BuildContext context, OrderEntryController ctrl,
      OrderEntryState st, FieldRow row) async {
    final field = row.config;
    final fKey = field.fieldKey.toUpperCase();
    final type = field.type.toLowerCase();
    final source = field.source.toLowerCase();
    final isPartition =
        fKey == 'PARTITION' || source == 'storedeptpartition' || source == 'partition';
    final isDate = type == 'date' || fKey.contains('DATE');
    final isDropdown = type == 'dropdown' && !isPartition;

    if (isPartition) {
      await context.push(Routes.selectPartition);
      return;
    }
    if (isDate) {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: now,
        firstDate: DateTime(now.year, now.month, now.day),
        lastDate: DateTime(now.year + 5),
      );
      if (picked != null) {
        String two(int n) => n.toString().padLeft(2, '0');
        ctrl.setFieldValue(
            field.fieldKey, '${two(picked.month)}/${two(picked.day)}/${picked.year}');
      }
      return;
    }
    if (isDropdown) {
      final options = _dropdownOptions(st, source);
      if (options.isEmpty) {
        await _textEntry(context, ctrl, field, st);
      } else {
        await _dropdown(context, ctrl, field, options, st.headerValues[field.fieldKey] ?? '');
      }
      return;
    }
    await _textEntry(context, ctrl, field, st);
  }

  List<String> _dropdownOptions(OrderEntryState st, String source) {
    switch (source) {
      case 'crreasoncodes':
      case 'crreasoncode':
        return st.config.crReasonCodes;
      case 'crtypes':
      case 'crtype':
        return st.config.crTypes;
      default:
        return st.config.data1LovValues;
    }
  }

  Future<void> _textEntry(BuildContext context, OrderEntryController ctrl,
      FormFieldConfig field, OrderEntryState st) async {
    final controller =
        TextEditingController(text: st.headerValues[field.fieldKey] ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text(field.label),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: field.fieldKey.toUpperCase() == 'COMMENTS' ? 4 : 1,
          keyboardType:
              field.fieldKey.toUpperCase() == 'PO' ? TextInputType.text : null,
          decoration: InputDecoration(hintText: 'Enter ${field.label}'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dctx), child: const Text('CANCEL')),
          TextButton(
              onPressed: () => Navigator.pop(dctx, controller.text),
              child: const Text('ACCEPT')),
        ],
      ),
    );
    if (result != null) ctrl.setFieldValue(field.fieldKey, result);
  }

  Future<void> _dropdown(BuildContext context, OrderEntryController ctrl,
      FormFieldConfig field, List<String> options, String selected) async {
    final result = await showDialog<String>(
      context: context,
      builder: (dctx) => SimpleDialog(
        title: Text(field.label),
        children: options
            .map((o) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(dctx, o),
                  child: Text(o,
                      style: TextStyle(
                          fontWeight:
                              o == selected ? FontWeight.bold : FontWeight.normal)),
                ))
            .toList(),
      ),
    );
    if (result != null) ctrl.setFieldValue(field.fieldKey, result);
  }
}

class _FieldRowWidget extends StatelessWidget {
  final FieldRow row;
  final String value;
  final VoidCallback onEdit;
  const _FieldRowWidget(
      {required this.row, required this.value, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final label = row.isMandatory ? '${row.config.label} *' : row.config.label;
    final placeholder = row.isMandatory ? 'Required' : 'Optional';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
          ),
          InkWell(
            onTap: onEdit,
            child: Container(
              width: 200,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFBBBBBB)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(value.isEmpty ? placeholder : value,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13)),
                  ),
                  const Icon(Icons.chevron_right, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
