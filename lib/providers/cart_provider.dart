import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _items = [];

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  List<Map<String, dynamic>> get items => List.unmodifiable(_items);

  double get total => _items.fold(
        0.0,
        (sum, item) => sum + ((item['lineTotal'] as num?)?.toDouble() ?? 0.0),
      );

  CartProvider() {
    _initAuthListener();
  }

  // ✅ FIX: listen to auth changes properly
  void _initAuthListener() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _items = [];
      notifyListeners();

      if (user != null) {
        _listenToCart();
      }
    });
  }

  void _listenToCart() {
    if (_userId.isEmpty) return;

    _firestore
        .collection('carts')
        .doc(_userId)
        .collection('items')
        .orderBy('addedAt')
        .snapshots()
        .listen((snapshot) {
      final newItems = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          ...data,
          'id': doc.id,
        };
      }).toList();

      _items = newItems;

      notifyListeners();
    });
  }

  Future<void> addItem(
    Map<String, dynamic> product, {
    int qty = 1,
  }) async {
    if (_userId.isEmpty) return;

    final price = (product['price'] as num).toDouble();

    final itemData = {
      ...product,
      'qty': qty,
      'unitPrice': price,
      'lineTotal': price * qty,
      'addedAt': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('carts')
        .doc(_userId)
        .collection('items')
        .doc(product['id'])
        .set(itemData, SetOptions(merge: true));
  }

  Future<void> removeItem(String itemId) async {
    if (_userId.isEmpty) return;

    await _firestore
        .collection('carts')
        .doc(_userId)
        .collection('items')
        .doc(itemId)
        .delete();
  }

  Future<void> updateItemQuantity(String itemId, int qty) async {
    if (_userId.isEmpty || qty <= 0) return;

    final docRef = _firestore
        .collection('carts')
        .doc(_userId)
        .collection('items')
        .doc(itemId);

    final snapshot = await docRef.get();
    final data = snapshot.data();

    if (data == null) return;

    final unitPrice = (data['unitPrice'] as num?)?.toDouble() ?? 0.0;

    await docRef.update({
      'qty': qty,
      'lineTotal': unitPrice * qty,
    });
  }

  Future<void> clear() async {
    if (_userId.isEmpty) return;

    final snapshot = await _firestore
        .collection('carts')
        .doc(_userId)
        .collection('items')
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  bool get isLoggedIn => _userId.isNotEmpty;
}
