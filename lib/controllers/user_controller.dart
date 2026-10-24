import '../utils/api_provider.dart';

class UserController {
  final ApiProvider _apiProvider = ApiProvider();

  Future<Map<String, dynamic>> fetchUser(String userId) => _apiProvider.getUser(userId);

  Future<Map<String, dynamic>> updateProfile(String userId, {String? fullName, String? email, String? phone}) {
    return _apiProvider.updateUser(userId, fullName: fullName,  phone: phone);
  }

  Future<Map<String, dynamic>> changePassword(String userId, String newPassword) {
    return _apiProvider.updatePassword(userId, newPassword);
  }
}