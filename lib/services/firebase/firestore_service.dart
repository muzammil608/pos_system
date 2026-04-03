import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get products => _db.collection('products');
  CollectionReference get orders => _db.collection('orders');
  CollectionReference get users => _db.collection('users');
}
