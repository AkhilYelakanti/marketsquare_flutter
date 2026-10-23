import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../orderentry/order_widgets.dart';
import 'invoices_controller.dart';

/// Port of native `InvoiceDetailScreen`: header + line items for one invoice.
class InvoiceDetailScreen extends ConsumerStatefulWidget {
  final String invoiceNumber;
  const InvoiceDetailScreen({super.key, this.invoiceNumber = ''});

  @override
  ConsumerState<InvoiceDetailScreen> createState() => _State();
}

class _State extends ConsumerState<InvoiceDetailScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.invoiceNumber.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) =>
          ref.read(invoicesControllerProvider.notifier).fetchDetail(widget.invoiceNumber));
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final st = ref.watch(invoicesControllerProvider);
    final detail = st.detail;
    final header = detail?.invoiceHeader.isNotEmpty == true ? detail!.invoiceHeader.first : null;

    return Scaffold(
      appBar: orderAppBar(subtitle: 'INVOICE ${widget.invoiceNumber}', height: 60),
      bottomNavigationBar: OrderBottomBar(onBack: () => context.pop()),
      body: st.loadingDetail
          ? const Center(child: CircularProgressIndicator())
          : st.detailError.isNotEmpty
              ? Center(
                  child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(st.detailError,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey))))
              : detail == null
                  ? const SizedBox.shrink()
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (header != null)
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              border: Border.all(color: const Color(0xFFDDDDDD)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Invoice #${header.invoiceNumber}',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: primary,
                                        fontSize: 15)),
                                if (header.invoiceDate.isNotEmpty)
                                  Text('Date: ${header.invoiceDate}'),
                                if (header.department.isNotEmpty)
                                  Text('Dept: ${header.department}'),
                                if (header.totalInvoiceAmount.isNotEmpty)
                                  Text('Total: \$${header.totalInvoiceAmount}',
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),
                        for (final line in detail.invoiceDetails)
                          ListTile(
                            dense: true,
                            title: Text(
                                line.description.isEmpty ? line.itemId : line.description),
                            subtitle: Text(
                                '# ${line.itemId}  •  pack ${line.packSize}  •  ord ${line.orderQty} / shp ${line.shippedQty}'),
                            trailing: Text('\$${line.invoiceAmount}',
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
    );
  }
}
