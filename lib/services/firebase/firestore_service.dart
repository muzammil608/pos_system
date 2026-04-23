import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get _uid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('User not authenticated');
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get globalProducts =>
      _db.collection('products');

  CollectionReference<Map<String, dynamic>> get products =>
      _db.collection('users').doc(_uid).collection('products');

  CollectionReference<Map<String, dynamic>> get orders =>
      _db.collection('users').doc(_uid).collection('orders');

  CollectionReference<Map<String, dynamic>> get users =>
      _db.collection('users');
}
