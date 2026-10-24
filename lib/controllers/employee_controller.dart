import 'package:app_store/utils/api_provider.dart';
import 'package:app_store/models/supplier.dart';

class EmployeeController {
  final ApiProvider _apiProvider = ApiProvider();

  Future<Map<String, dynamic>> fetchProducts() =>
      _apiProvider.getEmployeeProducts();

  Future<Map<String, dynamic>> addProduct({
    required String name,
    required String description,
    required String category,
    required double price,
    required int stock,
    String imageUrl = "",
  }) {
    return _apiProvider.addProduct(
      name: name,
      description: description,
      category: category,
      price: price,
      stock: stock,
      imageUrl: imageUrl,
    );
  }

  Future<List<Supplier>> fetchSuppliers() => _apiProvider.getSuppliers();

  Future<Map<String, dynamic>> createInvoice({
    required dynamic supplierId,
    required dynamic createdBy,
    required List<Map<String, dynamic>> items,
  }) {
    return _apiProvider.createInvoice(
      supplierId: supplierId,
      createdBy: createdBy,
      items: items,
    );
  }

  Future<Map<String, dynamic>> getInvoices({String status = "all"}) =>
      _apiProvider.getAllInvoices(status: status);

  Future<Map<String, dynamic>> verifyOcr(int invoiceId) =>
      _apiProvider.verifyOcr(invoiceId);

  Future<Map<String, dynamic>> reconcileStock(
    int invoiceId,
    List<Map<String, dynamic>> items,
  ) =>
      _apiProvider.reconcileStock(invoiceId, items);
}
