import 'package:app_store/models/product.dart';
import 'package:app_store/models/purchase_invoice.dart';

class ManagerUser {
  final String id, nom, prenom, cin, phone, role;
  ManagerUser.fromJson(Map<String, dynamic> json)
    : id = '${json['id_user'] ?? ''}',
      nom = '${json['nom'] ?? ''}',
      prenom = '${json['prenom'] ?? ''}',
      cin = '${json['cin'] ?? ''}'.padLeft(8, '0'),
      phone = '${json['teleph'] ?? ''}',
      role = '${json['role'] ?? ''}';
  String get name => '$prenom $nom'.trim();
}

class ManagerInvoice {
  final PurchaseInvoice invoice;
  final String supplier;
  ManagerInvoice.fromJson(Map<String, dynamic> json)
    : invoice = PurchaseInvoice.fromJson(json),
      supplier = '${json['supplier_name'] ?? json['supplier_id'] ?? ''}';
}

class ManagerDashboard {
  final List<Product> products;
  final List<ManagerInvoice> invoices;
  final List<ManagerUser> users;
  final Map<String, dynamic> stats;
  ManagerDashboard.fromJson(Map<String, dynamic> json)
    : products = (json['products'] as List)
          .map((p) => Product.fromJson(Map<String, dynamic>.from(p)))
          .toList(),
      invoices = (json['invoices'] as List)
          .map((i) => ManagerInvoice.fromJson(Map<String, dynamic>.from(i)))
          .toList(),
      users = (json['users'] as List)
          .map((u) => ManagerUser.fromJson(Map<String, dynamic>.from(u)))
          .toList(),
      stats = Map<String, dynamic>.from(json['stats']);
  int count(String key) => (stats[key] as num?)?.toInt() ?? 0;
  double get stockValue => (stats['stock_value'] as num?)?.toDouble() ?? 0;
  Map<String, int> get invoiceStatuses =>
      Map<String, dynamic>.from(stats['invoice_statuses'] ?? {})
          .map((key, value) => MapEntry(key, (value as num).toInt()));
}
