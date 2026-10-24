class Product {
  final int id;
  final String name;
  final String description;
  final String category;
  final double price;
  final int stock;
  final String? imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.stock,
    this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      price: double.parse(json['price'].toString()),
      stock: json['stock'] ?? 0,
      imageUrl: json['image_url'],
    );
  }

  bool get isOutOfStock => stock <= 0;
}
