import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/product_model.dart';
import 'firestore_service.dart';

class ProductService {
  final FirestoreService _firestore = FirestoreService();

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
}
