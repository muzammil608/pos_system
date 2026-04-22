import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../../models/product_model.dart';
import 'firestore_service.dart';
import 'dart:typed_data' show Uint8List;
import 'storage_service.dart';

class ProductService {
  final FirestoreService _firestore = FirestoreService();
  final StorageService _storage = StorageService();

  String get _uid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('User not authenticated');
    }
    return user.uid;
  }

  Stream<List<Product>> get streamProducts {
    return _firestore.products.snapshots().map((snapshot) {
      final ownDocs = snapshot.docs.where((doc) {
        final ownerId = doc.data()['ownerId']?.toString();
        return ownerId == _uid;
      }).toList();

      // Backward compatibility for old records created before ownerId existed.
      final legacyDocs = snapshot.docs.where((doc) {
        final ownerId = doc.data()['ownerId'];
        return ownerId == null || ownerId.toString().trim().isEmpty;
      }).toList();

      final visibleDocs = ownDocs.isNotEmpty ? ownDocs : legacyDocs;

      return visibleDocs.map((doc) {
        return Product.fromMap(doc.data(), doc.id);
      }).toList();
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
        'ownerId': _uid,
        'createdAt': FieldValue.serverTimestamp(),
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
      final doc = await _firestore.products.doc(id).get();
      if (!doc.exists) {
        return 'Product not found';
      }

      final ownerId = doc.data()?['ownerId']?.toString();
      if (ownerId != null && ownerId.isNotEmpty && ownerId != _uid) {
        return 'Not authorized to update this product';
      }

      await _firestore.products.doc(id).update({
        'name': name,
        'price': price,
        'category': category,
        // Claim legacy products to current user on first update.
        'ownerId': _uid,
      });
      return 'Product updated successfully';
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<String?> deleteProduct(String id) async {
    try {
      final doc = await _firestore.products.doc(id).get();
      if (!doc.exists) {
        return 'Product not found';
      }

      final ownerId = doc.data()?['ownerId']?.toString();
      if (ownerId != null && ownerId.isNotEmpty && ownerId != _uid) {
        return 'Not authorized to delete this product';
      }

      await _firestore.products.doc(id).delete();
      return 'Product deleted successfully';
    } catch (e) {
      return 'Error: $e';
    }
  }
}
