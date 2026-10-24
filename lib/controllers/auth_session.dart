import 'package:flutter/foundation.dart';

class AuthSession extends ChangeNotifier {
  AuthSession._internal();
  static final AuthSession instance = AuthSession._internal();

  Map<String, dynamic>? currentUser;

  bool get isLoggedIn => currentUser != null;
  String get username => currentUser?['id_user'] ?? 'Account';
  String get nom => currentUser?['nom'] ?? 'Account';
  String get prenom => currentUser?['prenom'] ?? 'Account';
  void setUser(Map<String, dynamic> user) {
    currentUser = user;
    notifyListeners();
  }

  void logout() {
    currentUser = null;
    notifyListeners();
  }
}
