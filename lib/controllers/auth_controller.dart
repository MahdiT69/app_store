import 'package:app_store/utils/api_provider.dart';

class AuthController {
  final ApiProvider _apiProvider = ApiProvider();

  Future<Map<String, dynamic>> login(String username, String password) async {
    if (username.isEmpty || password.isEmpty) {
      return {"success": false, "message": "Please fill in all fields"};
    }
    return await _apiProvider.login(username, password);
  }
}
