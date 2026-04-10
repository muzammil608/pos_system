import 'package:flutter/material.dart';

class CartProvider with ChangeNotifier {
  final List<Map<String, dynamic>> _items = [];

  List<Map<String, dynamic>> get items => _items;

  void addItem(Map<String, dynamic> product, {int qty = 1}) {
    _items.add({
      ...product,
      'qty': qty,
      'unitPrice': product['price'],
      'lineTotal': product['price'] * qty,
    });
    notifyListeners();
  }

  void removeItem(int index) {
    _items.removeAt(index);
    notifyListeners();
  }

  void updateItemQuantity(int index, int qty) {
    if (index < 0 || index >= _items.length || qty <= 0) return;

    final item = _items[index];
    final unitPrice = (item['unitPrice'] ?? item['price'] ?? 0) as num;

    _items[index] = {
      ...item,
      'qty': qty,
      'unitPrice': unitPrice.toDouble(),
      'lineTotal': unitPrice.toDouble() * qty,
    };
    notifyListeners();
  }

  double get total {
    return _items.fold(
        0, (sum, item) => sum + (item['lineTotal'] ?? item['price']));
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
