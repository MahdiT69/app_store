import 'package:app_store/utils/constants.dart';

// Flask serializes database dates as HTTP dates; also accept ISO 8601.
DateTime? _parseInvoiceDate(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  final isoDate = DateTime.tryParse(text);
  if (isoDate != null) return isoDate;

  final match = RegExp(
    r'^[A-Za-z]{3}, (\d{2}) ([A-Za-z]{3}) (\d{4}) (\d{2}):(\d{2}):(\d{2}) GMT$',
  ).firstMatch(text);
  if (match == null) return null;

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final month = months.indexOf(match[2]!);
  if (month == -1) return null;

  return DateTime.utc(
    int.parse(match[3]!),
    month + 1,
    int.parse(match[1]!),
    int.parse(match[4]!),
    int.parse(match[5]!),
    int.parse(match[6]!),
  );
}

class PurchaseInvoice {
  final int id;
  final String supplierId;
  final String createdBy;
  final String employeeName;
  final String status;
  final String? rejectionReason;
  final DateTime? createdAt;
  final int productsCount;
  final int totalQty;
  final List<PurchaseInvoiceItem> items;
  final InvoiceDelivery? delivery;

  PurchaseInvoice({
    required this.id,
    required this.supplierId,
    required this.createdBy,
    required this.employeeName,
    required this.status,
    this.rejectionReason,
    this.createdAt,
    required this.productsCount,
    required this.totalQty,
    this.items = const [],
    this.delivery,
  });

  factory PurchaseInvoice.fromJson(Map<String, dynamic> json) {
    final parsedDate = _parseInvoiceDate(json['created_at']);

    List<PurchaseInvoiceItem> parsedItems = [];
    if (json['items'] != null && json['items'] is List) {
      parsedItems = (json['items'] as List)
          .map((i) => PurchaseInvoiceItem.fromJson(i))
          .toList();
    }

    InvoiceDelivery? parsedDelivery;
    if (json['delivery'] != null && json['delivery'] is Map<String, dynamic>) {
      parsedDelivery = InvoiceDelivery.fromJson(json['delivery']);
    }

    return PurchaseInvoice(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      supplierId: json['supplier_id']?.toString() ?? '',
      createdBy: json['created_by']?.toString() ?? '',
      employeeName: json['employee_name']?.toString() ?? 'Employee',
      status: json['status']?.toString().toLowerCase() ?? 'pending',
      rejectionReason: json['rejection_reason']?.toString(),
      createdAt: parsedDate,
      productsCount: json['products_count'] is int
          ? json['products_count']
          : int.tryParse(json['products_count']?.toString() ?? '0') ?? 0,
      totalQty: json['total_qty'] is int
          ? json['total_qty']
          : int.tryParse(json['total_qty']?.toString() ?? '0') ?? 0,
      items: parsedItems,
      delivery: parsedDelivery,
    );
  }

  String get formattedId => "#INV-${id.toString().padLeft(4, '0')}";
}

class PurchaseInvoiceItem {
  final int id;
  final int productId;
  final String productName;
  final String imageUrl;
  final String category;
  final double price;
  final int qtyRequested;
  int? qtyConfirmed;

  PurchaseInvoiceItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.category,
    required this.price,
    required this.qtyRequested,
    this.qtyConfirmed,
  });

  factory PurchaseInvoiceItem.fromJson(Map<String, dynamic> json) {
    return PurchaseInvoiceItem(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      productId: json['product_id'] is int
          ? json['product_id']
          : int.parse(json['product_id'].toString()),
      productName: json['product_name']?.toString() ?? 'Product',
      imageUrl: Constants.resolveImage(json['image_url']?.toString() ?? ''),
      category: json['category']?.toString() ?? 'General',
      price: json['price'] != null
          ? double.tryParse(json['price'].toString()) ?? 0.0
          : 0.0,
      qtyRequested: json['qty_requested'] is int
          ? json['qty_requested']
          : int.tryParse(json['qty_requested']?.toString() ?? '0') ?? 0,
      qtyConfirmed: json['qty_confirmed'] != null
          ? int.tryParse(json['qty_confirmed'].toString())
          : null,
    );
  }
}

class InvoiceDelivery {
  final int id;
  final String pdfPath;
  final DateTime? deliveryDate;
  final String? note;
  final DateTime? uploadedAt;

  InvoiceDelivery({
    required this.id,
    required this.pdfPath,
    this.deliveryDate,
    this.note,
    this.uploadedAt,
  });

  factory InvoiceDelivery.fromJson(Map<String, dynamic> json) {
    return InvoiceDelivery(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      pdfPath: Constants.resolveImage(json['pdf_path']?.toString() ?? ''),
      deliveryDate: _parseInvoiceDate(json['delivery_date']),
      note: json['note']?.toString(),
      uploadedAt: _parseInvoiceDate(json['uploaded_at']),
    );
  }
}
