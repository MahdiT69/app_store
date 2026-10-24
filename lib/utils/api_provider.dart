import 'dart:convert';

import 'package:app_store/models/app_user.dart';
import 'package:app_store/models/supplier.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'constants.dart';

import 'package:app_store/models/product.dart';

class ApiProvider {
  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse("${Constants.baseUrl}/login");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id_user": username, "pw_user": password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {"success": true, "user": data['user']};
      } else {
        return {"success": false, "message": data['message'] ?? "Login failed"};
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  Future<Map<String, dynamic>> getProducts({
    String search = "",
    String category = "all",
    int page = 1,
    int pageSize = 6,
    String sort = "recent",
  }) async {
    final uri = Uri.parse("${Constants.baseUrl}/products/").replace(
      queryParameters: {
        "search": search,
        "category": category,
        "page": page.toString(),
        "page_size": pageSize.toString(),
        "sort": sort,
      },
    );

    try {
      final response = await http.get(uri);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final products = (data['products'] as List)
            .map((p) => Product.fromJson(p))
            .toList();
        return {
          "success": true,
          "products": products,
          "total": data['total'] ?? 0,
        };
      }
      return {"success": false, "message": "Failed to load products"};
    } catch (e) {
      debugPrint("getProducts error: $e");
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  Future<List<String>> getCategories() async {
    final uri = Uri.parse("${Constants.baseUrl}/products/categories");
    try {
      final response = await http.get(uri);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return List<String>.from(data['categories']);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getUser(String userId) async {
    final uri = Uri.parse("${Constants.baseUrl}/users/$userId");
    try {
      final response = await http.get(uri);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {"success": true, "user": AppUser.fromJson(data['user'])};
      }
      return {
        "success": false,
        "message": data['message'] ?? "Failed to load user",
      };
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  Future<Map<String, dynamic>> updateUser(
    String userId, {
    String? fullName,
    String? phone,
  }) async {
    final uri = Uri.parse("${Constants.baseUrl}/users/$userId");
    try {
      final response = await http.put(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"full_name": fullName, "phone": phone}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {"success": true, "user": AppUser.fromJson(data['user'])};
      }
      return {"success": false, "message": data['message'] ?? "Update failed"};
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  Future<Map<String, dynamic>> updatePassword(
    String userId,
    String newPassword,
  ) async {
    final uri = Uri.parse("${Constants.baseUrl}/users/$userId/password");
    try {
      final response = await http.put(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"new_pw_user": newPassword}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {"success": true};
      }
      return {"success": false, "message": data['message'] ?? "Update failed"};
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  Future<Map<String, dynamic>> getEmployeeProducts() async {
    final uri = Uri.parse("${Constants.baseUrl}/products/employee-list");
    try {
      final response = await http.get(uri);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final products = (data['products'] as List)
            .map((p) => Product.fromJson(p))
            .toList();
        return {"success": true, "products": products};
      }
      return {"success": false, "message": "Failed to load products"};
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  Future<Map<String, dynamic>> addProduct({
    required String name,
    required String description,
    required String category,
    required double price,
    required int stock,
    String imageUrl = "",
  }) async {
    final uri = Uri.parse("${Constants.baseUrl}/products/");
    try {
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "description": description,
          "category": category,
          "price": price,
          "stock": stock,
          "image_url": imageUrl,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 201 && data['success'] == true) {
        return {"success": true};
      }
      return {
        "success": false,
        "message": data['message'] ?? "Failed to add product",
      };
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  Future<List<Supplier>> getSuppliers() async {
    final uri = Uri.parse("${Constants.baseUrl}/users/suppliers");
    try {
      final response = await http.get(uri);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return (data['suppliers'] as List)
            .map((s) => Supplier.fromJson(s))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> createInvoice({
    required dynamic supplierId,
    required dynamic createdBy,
    required List<Map<String, dynamic>> items,
  }) async {
    final uri = Uri.parse("${Constants.baseUrl}/invoices/");
    try {
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "supplier_id": supplierId,
          "created_by": createdBy,
          "items": items,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 201 && data['success'] == true) {
        return {"success": true};
      }
      return {
        "success": false,
        "message": data['message'] ?? "Failed to create invoice",
      };
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  Future<Map<String, dynamic>> getSupplierInvoices({
    required String supplierId,
    String status = "all",
  }) async {
    final uri = Uri.parse(
      "${Constants.baseUrl}/invoices/supplier/$supplierId",
    ).replace(queryParameters: {"status": status});

    try {
      final response = await http.get(uri);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {"success": true, "invoices": data['invoices']};
      }
      return {"success": false, "message": "Failed to load invoices"};
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  Future<Map<String, dynamic>> getSupplierStats(String supplierId) async {
    final uri = Uri.parse(
      "${Constants.baseUrl}/invoices/supplier/$supplierId/stats",
    );
    try {
      final response = await http.get(uri);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {"success": true, "stats": data['stats']};
      }
      return {"success": false};
    } catch (e) {
      return {"success": false};
    }
  }

  Future<Map<String, dynamic>> getInvoiceDetail(int invoiceId) async {
    final uri = Uri.parse("${Constants.baseUrl}/invoices/$invoiceId");
    try {
      final response = await http.get(uri);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {"success": true, "invoice": data['invoice']};
      }
      return {"success": false, "message": "Invoice not found"};
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  Future<Map<String, dynamic>> confirmInvoiceApi({
    required int invoiceId,
    required List<Map<String, dynamic>> items,
  }) async {
    final uri = Uri.parse("${Constants.baseUrl}/invoices/$invoiceId/confirm");
    try {
      final response = await http.put(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"items": items}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {"success": true};
      }
      return {"success": false, "message": data['message'] ?? "Confirmation failed"};
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  Future<Map<String, dynamic>> rejectInvoiceApi({
    required int invoiceId,
    String? reason,
  }) async {
    final uri = Uri.parse("${Constants.baseUrl}/invoices/$invoiceId/reject");
    try {
      final response = await http.put(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"reason": reason ?? ""}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {"success": true};
      }
      return {"success": false, "message": data['message'] ?? "Rejection failed"};
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  Future<Map<String, dynamic>> uploadDeliveryApi({
    required int invoiceId,
    List<int>? fileBytes,
    String? fileName,
    String? deliveryDate,
    String? note,
  }) async {
    final uri = Uri.parse("${Constants.baseUrl}/invoices/deliveries");
    try {
      if (fileBytes != null && fileBytes.isNotEmpty && fileName != null) {
        final request = http.MultipartRequest("POST", uri);
        request.fields['invoice_id'] = invoiceId.toString();
        if (deliveryDate != null) request.fields['delivery_date'] = deliveryDate;
        if (note != null) request.fields['note'] = note;

        request.files.add(
          http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
        );

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        final data = jsonDecode(response.body);
        if (response.statusCode == 201 && data['success'] == true) {
          return {"success": true, "pdf_path": data['pdf_path']};
        }
        return {"success": false, "message": data['message'] ?? "Upload failed"};
      } else {
        final response = await http.post(
          uri,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "invoice_id": invoiceId,
            "delivery_date": deliveryDate,
            "note": note ?? "",
          }),
        );
        final data = jsonDecode(response.body);
        if (response.statusCode == 201 && data['success'] == true) {
          return {"success": true, "pdf_path": data['pdf_path']};
        }
        return {"success": false, "message": data['message'] ?? "Upload failed"};
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  Future<Map<String, dynamic>> getAllInvoices({String status = "all"}) async {
    final uri = Uri.parse("${Constants.baseUrl}/invoices/all").replace(queryParameters: {"status": status});
    try {
      final response = await http.get(uri);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {"success": true, "invoices": data['invoices']};
      }
      return {"success": false, "message": "Failed to load invoices"};
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  Future<Map<String, dynamic>> verifyOcr(int invoiceId) async {
    final uri = Uri.parse("${Constants.baseUrl}/invoices/$invoiceId/verify-ocr");
    try {
      final response = await http.post(uri);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {"success": true, "ocr": data};
      }
      return {"success": false, "message": data['message'] ?? "OCR verification failed"};
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  Future<Map<String, dynamic>> reconcileStock(int invoiceId, List<Map<String, dynamic>> items) async {
    final uri = Uri.parse("${Constants.baseUrl}/invoices/$invoiceId/reconcile-stock");
    try {
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"items": items}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {"success": true};
      }
      return {"success": false, "message": data['message'] ?? "Stock reconciliation failed"};
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }
}
