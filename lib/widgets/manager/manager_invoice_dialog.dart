import 'package:flutter/material.dart';
import 'package:app_store/controllers/manager_controller.dart';
import 'package:app_store/models/purchase_invoice.dart';
import 'package:app_store/widgets/manager/manager_components.dart';

class ManagerInvoiceDialog extends StatefulWidget {
  final ManagerController controller;
  final int invoiceId;
  final String supplier;
  const ManagerInvoiceDialog({
    super.key,
    required this.controller,
    required this.invoiceId,
    required this.supplier,
  });
  @override
  State<ManagerInvoiceDialog> createState() => _ManagerInvoiceDialogState();
}

class _ManagerInvoiceDialogState extends State<ManagerInvoiceDialog> {
  late Future<PurchaseInvoice> _invoice = widget.controller.fetchInvoice(
    widget.invoiceId,
  );
  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: ManagerColors.card,
    title: Text(
      'Purchase order #INV-${widget.invoiceId.toString().padLeft(4, '0')}',
    ),
    content: SizedBox(
      width: 760,
      child: SingleChildScrollView(
        child: FutureBuilder<PurchaseInvoice>(
          future: _invoice,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Could not load invoice. ${snapshot.error}'),
                  TextButton(
                    onPressed: () => setState(() {
                      _invoice = widget.controller.fetchInvoice(
                        widget.invoiceId,
                      );
                    }),
                    child: const Text('Retry'),
                  ),
                ],
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final invoice = snapshot.data!;
            final date = invoice.createdAt;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ManagerStatusBadge(invoice.status),
                const SizedBox(height: 16),
                Text('Supplier: ${widget.supplier}'),
                Text('Employee: ${invoice.employeeName}'),
                Text(
                  'Created: ${date == null ? '-' : '${date.day}/${date.month}/${date.year}'}',
                ),
                if (invoice.rejectionReason?.isNotEmpty == true)
                  Text('Rejection reason: ${invoice.rejectionReason}'),
                const SizedBox(height: 20),
                ManagerTable(
                  columns: const ['Product', 'Requested', 'Confirmed'],
                  rows: invoice.items
                      .map(
                        (item) => DataRow(
                          cells: [
                            DataCell(Text(item.productName)),
                            DataCell(Text('${item.qtyRequested}')),
                            DataCell(
                              Text(item.qtyConfirmed?.toString() ?? '-'),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                  emptyMessage: 'No items in this invoice.',
                ),
                if (invoice.delivery != null) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Delivery receipt',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SelectableText(invoice.delivery!.pdfPath),
                  if (invoice.delivery!.deliveryDate case final date?)
                    Text('Delivery: ${date.day}/${date.month}/${date.year}'),
                  if (invoice.delivery!.note?.isNotEmpty == true)
                    Text(invoice.delivery!.note!),
                ],
              ],
            );
          },
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Close'),
      ),
    ],
  );
}
