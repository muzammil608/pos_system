import 'package:flutter/foundation.dart';
import '../services/firebase/product_service.dart';
import '../models/product_model.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _service = ProductService();
  List<Product> _products = [];
  bool _isLoading = false;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;

  Stream<List<Product>> get productsStream => _service.streamProducts;

  Future<String?> createProduct({
    required String name,
    required double price,
    required String category,
  }) async {
    setLoading(true);
    try {
      final result = await _service.createProduct(
        name: name,
        price: price,
        category: category,
      );
      notifyListeners();
      return result;
    } finally {
      setLoading(false);
    }
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Add update/delete methods later
}
