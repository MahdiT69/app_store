import 'package:app_store/models/product.dart';

class CartLine {
  final Product product;
  int quantity;
  CartLine({required this.product, this.quantity = 1});

  double get lineTotal => product.price * quantity;
}

class CartController {
  CartController._internal();
  static final CartController instance = CartController._internal();

  final List<CartLine> _lines = [];
  List<CartLine> get lines => List.unmodifiable(_lines);

  int get count => _lines.fold(0, (sum, l) => sum + l.quantity);
  double get total => _lines.fold(0.0, (sum, l) => sum + l.lineTotal);

  void add(Product product, int qty) {
    final index = _lines.indexWhere((l) => l.product.id == product.id);
    if (index >= 0) {
      _lines[index].quantity = (_lines[index].quantity + qty).clamp(
        1,
        product.stock,
      );
    } else {
      _lines.add(CartLine(product: product, quantity: qty));
    }
  }

  void setQuantity(int productId, int qty) {
    final index = _lines.indexWhere((l) => l.product.id == productId);
    if (index >= 0) {
      if (qty <= 0) {
        _lines.removeAt(index);
      } else {
        _lines[index].quantity = qty.clamp(1, _lines[index].product.stock);
      }
    }
  }

  void remove(int productId) {
    _lines.removeWhere((l) => l.product.id == productId);
  }

  void clear() => _lines.clear();
}
