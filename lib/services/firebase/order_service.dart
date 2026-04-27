import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';

class OrderService {
  final FirestoreService _firestore = FirestoreService();

  Future<DocumentReference> createOrder({
    required List<Map<String, dynamic>> items,
    required double total,
    String orderType = 'takeaway',
    String? tableNumber,
    String? customerName,
    String paymentMethod = 'cash',
    double tenderedAmount = 0.0,
    double change = 0.0,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('User not authenticated');
    }

    final counterRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('counters')
        .doc('order_number');

    final nextNumber = await FirebaseFirestore.instance
        .runTransaction<int>((transaction) async {
      final snap = await transaction.get(counterRef);

      final current = (snap.data()?['number'] as int?) ?? 0;
      final newNumber = current + 1;

      transaction.set(counterRef, {'number': newNumber});

      return newNumber;
    });

    return await _firestore.orders.add({
      'items': items,
      'total': total,
      'status': 'pending',
      'orderType': orderType,
      if (tableNumber != null) 'tableNumber': tableNumber,
      if (customerName != null && customerName.trim().isNotEmpty)
        'customerName': customerName.trim(),
      'paymentMethod': paymentMethod,
      'tenderedAmount': tenderedAmount,
      'change': change,
      'orderNumber': nextNumber,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteCompletedOrders() async {
    final snapshot =
        await _firestore.orders.where('status', isEqualTo: 'completed').get();

    final batch = FirebaseFirestore.instance.batch();

    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  Stream<Map<String, int>> getTableOccupancy() {
    return _firestore.orders
        .where('status', whereIn: ['pending', 'ready'])
        .snapshots()
        .map((snapshot) {
          final occupied = <String, int>{};

          for (var doc in snapshot.docs) {
            final data = doc.data();
            final table = data['tableNumber'] as String?;

            if (table != null && data['orderType'] == 'dine_in') {
              occupied[table] = (occupied[table] ?? 0) + 1;
            }
          }

          return occupied;
        });
  }

  Stream<QuerySnapshot> getOrders() {
    return _firestore.orders.orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> updateStatus(String id, String status) async {
    await _firestore.orders.doc(id).update({'status': status});
  }

  Future<void> completeReadyOrders() async {
    final snapshot =
        await _firestore.orders.where('status', isEqualTo: 'ready').get();

    for (var doc in snapshot.docs) {
      await doc.reference.update({'status': 'completed'});
    }
  }
}
