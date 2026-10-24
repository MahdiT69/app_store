import 'package:app_store/models/purchase_invoice.dart';
import 'package:app_store/utils/api_provider.dart';

class SupplierController {
  final ApiProvider _apiProvider = ApiProvider();

  Future<List<PurchaseInvoice>> fetchInvoices({
    required String supplierId,
    String status = "all",
  }) async {
    final result = await _apiProvider.getSupplierInvoices(
      supplierId: supplierId,
      status: status,
    );
    if (result['success'] == true && result['invoices'] is List) {
      return (result['invoices'] as List)
          .map((i) => PurchaseInvoice.fromJson(i))
          .toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> fetchStats(String supplierId) async {
    final result = await _apiProvider.getSupplierStats(supplierId);
    if (result['success'] == true && result['stats'] is Map<String, dynamic>) {
      return result['stats'];
    }
    return {"pending": 0, "confirmed": 0, "shipped": 0, "total": 0};
  }

  Future<PurchaseInvoice?> fetchInvoiceDetail(int invoiceId) async {
    final result = await _apiProvider.getInvoiceDetail(invoiceId);
    if (result['success'] == true && result['invoice'] != null) {
      return PurchaseInvoice.fromJson(result['invoice']);
    }
    return null;
  }

  Future<Map<String, dynamic>> confirmInvoice({
    required int invoiceId,
    required List<Map<String, dynamic>> items,
  }) {
    return _apiProvider.confirmInvoiceApi(
      invoiceId: invoiceId,
      items: items,
    );
  }

  Future<Map<String, dynamic>> rejectInvoice({
    required int invoiceId,
    String? reason,
  }) {
    return _apiProvider.rejectInvoiceApi(
      invoiceId: invoiceId,
      reason: reason,
    );
  }

  Future<Map<String, dynamic>> uploadDelivery({
    required int invoiceId,
    List<int>? fileBytes,
    String? fileName,
    String? deliveryDate,
    String? note,
  }) {
    return _apiProvider.uploadDeliveryApi(
      invoiceId: invoiceId,
      fileBytes: fileBytes,
      fileName: fileName,
      deliveryDate: deliveryDate,
      note: note,
    );
  }
}
