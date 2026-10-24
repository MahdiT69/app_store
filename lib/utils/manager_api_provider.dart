import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:app_store/utils/constants.dart';

class ManagerApiProvider {
  Future<Map<String, dynamic>> _request(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('${Constants.baseUrl}/manager/$path');
    try {
      final response =
          await (body == null
                  ? http.get(uri)
                  : http.post(
                      uri,
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode(body),
                    ))
              .timeout(const Duration(seconds: 20));
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode >= 400 || data['success'] != true) {
        throw Exception(
          data['message'] ?? 'Request failed (${response.statusCode})',
        );
      }
      return data;
    } on FormatException {
      throw Exception('The server returned an invalid response.');
    }
  }

  Future<Map<String, dynamic>> dashboard() => _request('dashboard');
  Future<Map<String, dynamic>> invoice(int id) => _request('invoices/$id');
  Future<void> createUser(Map<String, dynamic> user) async {
    await _request('users', body: user);
  }
}
