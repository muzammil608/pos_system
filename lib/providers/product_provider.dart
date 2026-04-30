import 'package:flutter/foundation.dart';
import '../services/firebase/product_service.dart';
import '../models/product_model.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _service = ProductService();
  final List<Product> _products = [];
  bool _isLoading = false;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;

  Stream<List<Product>> get productsStream => _service.streamProducts;

  Future<String?> createProduct({
    required String name,
    required double price,
    required String category,
    int? iconCodePoint,
  }) async {
    setLoading(true);
    try {
      final result = await _service.createProduct(
        name: name,
        price: price,
        category: category,
        iconCodePoint: iconCodePoint,
      );
      notifyListeners();
      return result;
    } finally {
      setLoading(false);
    }
  }

  Future<String?> updateProduct({
    required String id,
    required String name,
    required double price,
    required String category,
    int? iconCodePoint,
  }) async {
    setLoading(true);
    try {
      final result = await _service.updateProduct(
        id: id,
        name: name,
        price: price,
        category: category,
        iconCodePoint: iconCodePoint,
      );
      notifyListeners();
      return result;
    } finally {
      setLoading(false);
    }
  }

  Future<String?> deleteProduct(String id) async {
    setLoading(true);
    try {
      final result = await _service.deleteProduct(id);
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
}
