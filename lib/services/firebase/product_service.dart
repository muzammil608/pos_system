import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
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
      print('Products snapshot: ${snapshot.docs.length} docs');
      final productList = snapshot.docs
          .map((doc) {
            print('Doc ${doc.id}: ${doc.data()}');
            return Product.fromMap(doc.data(), doc.id);
          })
          .where((product) => product.name != 'Unknown') // Filter bad data
          .toList();
      print('Parsed ${productList.length} products');
      return productList;
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
      print('Product created with image: $imageUrl');
      return 'Product created successfully';
    } catch (e) {
      print('Create product error: $e');
      return 'Error: $e';
    }
  }
}
