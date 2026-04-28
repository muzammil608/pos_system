import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/product_model.dart';
import 'firestore_service.dart';

class ProductService {
  final FirestoreService _firestore = FirestoreService();

  Stream<List<Product>> get streamProducts {
    return _firestore.products.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Product.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<String?> createProduct({
    required String name,
    required double price,
    required String category,
  }) async {
    try {
      final productData = {
        'name': name,
        'price': price,
        'category': category,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.products.add(productData);
      return 'Product created successfully';
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<String?> updateProduct({
    required String id,
    required String name,
    required double price,
    required String category,
  }) async {
    try {
      await _firestore.products.doc(id).update({
        'name': name,
        'price': price,
        'category': category,
      });
      return 'Product updated successfully';
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<String?> deleteProduct(String id) async {
    try {
      await _firestore.products.doc(id).delete();
      return 'Product deleted successfully';
    } catch (e) {
      return 'Error: $e';
    }
  }
}
