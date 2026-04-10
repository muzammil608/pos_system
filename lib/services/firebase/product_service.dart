import 'package:uuid/uuid.dart';
import '../../models/product_model.dart';
import 'firestore_service.dart';
import 'dart:typed_data' show Uint8List;
import 'storage_service.dart';

class ProductService {
  final FirestoreService _firestore = FirestoreService();
  final StorageService _storage = StorageService();

  Stream<List<Product>> get streamProducts {
    return _firestore.products.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) {
            return Product.fromMap(doc.data(), doc.id);
          })
          .where((product) => product.name != 'Unknown')
          .toList();
    });
  }

  Future<String?> createProduct({
    required String name,
    required double price,
    required String category,
    Uint8List? imageBytes,
  }) async {
    try {
      String? imageUrl;
      if (imageBytes != null) {
        final fileName = const Uuid().v4();
        imageUrl = await _storage.uploadImage(
          imageBytes: imageBytes,
          nonFilename: fileName,
        );
      }

      final productData = {
        'name': name,
        'price': price,
        'category': category,
        if (imageUrl != null) 'imageUrl': imageUrl,
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
