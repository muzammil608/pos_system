import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/product_model.dart';
import 'firestore_service.dart';

class ProductService {
  final FirestoreService _firestore = FirestoreService();
  final String ownerId;

  ProductService(this.ownerId);

  Stream<List<Product>> get streamProducts {
    return _firestore.products
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Product.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<String?> createProduct({
    required String name,
    required double price,
    required String category,
    int? iconCodePoint,
  }) async {
    try {
      final productData = {
        'name': name,
        'price': price,
        'category': category,
        'ownerId': ownerId,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (iconCodePoint != null) {
        productData['iconCodePoint'] = iconCodePoint;
      }

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
    int? iconCodePoint,
  }) async {
    try {
      final updateData = {
        'name': name,
        'price': price,
        'category': category,
        'ownerId': ownerId,
      };

      if (iconCodePoint != null) {
        updateData['iconCodePoint'] = iconCodePoint;
      }

      await _firestore.products.doc(id).update(updateData);
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
