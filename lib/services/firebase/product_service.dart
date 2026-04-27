import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../../models/product_model.dart';
import 'firestore_service.dart';
import 'dart:typed_data' show Uint8List;
import 'storage_service.dart';

class ProductService {
  final FirestoreService _firestore = FirestoreService();
  final StorageService _storage = StorageService();

  Stream<List<Product>> get streamProducts {
    return _firestore.globalProducts.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Product.fromMap(doc.data(), doc.id))
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
        'createdAt': FieldValue.serverTimestamp(),
        if (imageUrl != null) 'imageUrl': imageUrl,
      };

      await _firestore.globalProducts.add(productData);
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
      await _firestore.globalProducts.doc(id).update({
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
      await _firestore.globalProducts.doc(id).delete();
      return 'Product deleted successfully';
    } catch (e) {
      return 'Error: $e';
    }
  }
}
