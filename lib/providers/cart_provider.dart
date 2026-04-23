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
        (sum, item) {
          final qty = (item['qty'] as num?)?.toDouble() ?? 1.0;
          final price = (item['price'] as num?)?.toDouble() ?? 0.0;
          return sum + (qty * price);
        },
      );

  CartProvider() {
    _initAuthListener();
  }

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
        .snapshots()
        .listen((snapshot) {
      final newItems = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          ...data,
          'cartDocId': doc.id, // ✅ Use different field name
        };
      }).toList();

      _items = newItems;
      notifyListeners();
    });
  }

  // ✅ SIMPLIFIED & FIXED - Uses random ID for each add
  Future<void> addItem(Map<String, dynamic> product) async {
    if (_userId.isEmpty) return;

    try {
      final qty = product['qty'] as int? ?? 1;
      final name = product['name'] as String? ?? 'Unknown';
      final price = (product['price'] as num?)?.toDouble() ?? 0.0;

      // ✅ Use random ID for each cart item (no conflicts)
      final cartItemId = _firestore.collection('temp').doc().id;

      final docRef = _firestore
          .collection('carts')
          .doc(_userId)
          .collection('items')
          .doc(cartItemId);

      await docRef.set({
        'productId': product['id'] ?? cartItemId,
        'name': name,
        'price': price,
        'qty': qty,
        'lineTotal': price * qty,
        'addedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Added to cart: $name x$qty');
    } catch (e) {
      debugPrint('❌ Cart error: $e');
    }
  }

  Future<void> removeItem(String cartDocId) async {
    if (_userId.isEmpty) return;

    try {
      await _firestore
          .collection('carts')
          .doc(_userId)
          .collection('items')
          .doc(cartDocId)
          .delete();
    } catch (e) {
      debugPrint('Remove error: $e');
    }
  }

  Future<void> updateItemQuantity(String cartDocId, int qty) async {
    if (_userId.isEmpty || qty <= 0) return;

    try {
      final docRef = _firestore
          .collection('carts')
          .doc(_userId)
          .collection('items')
          .doc(cartDocId);

      final snapshot = await docRef.get();
      final data = snapshot.data();

      if (data == null) return;

      final price = (data['price'] as num?)?.toDouble() ?? 0.0;

      await docRef.update({
        'qty': qty,
        'lineTotal': price * qty,
      });
    } catch (e) {
      debugPrint('Update qty error: $e');
    }
  }

  Future<void> clear() async {
    if (_userId.isEmpty) return;

    try {
      final snapshot = await _firestore
          .collection('carts')
          .doc(_userId)
          .collection('items')
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint('Clear cart error: $e');
    }
  }

  bool get isLoggedIn => _userId.isNotEmpty;
}
