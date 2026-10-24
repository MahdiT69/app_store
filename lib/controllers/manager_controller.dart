import 'package:app_store/models/manager_dashboard.dart';
import 'package:app_store/models/purchase_invoice.dart';
import 'package:app_store/utils/manager_api_provider.dart';

class ManagerController {
  final ManagerApiProvider _api;
  ManagerController({ManagerApiProvider? api})
    : _api = api ?? ManagerApiProvider();

  Future<ManagerDashboard> fetchDashboard() async =>
      ManagerDashboard.fromJson(await _api.dashboard());

  Future<PurchaseInvoice> fetchInvoice(int id) async =>
      PurchaseInvoice.fromJson((await _api.invoice(id))['invoice']);

  Future<void> createUser(Map<String, dynamic> user) => _api.createUser(user);
}
