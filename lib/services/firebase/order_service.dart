import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';

class OrderService {
  final FirestoreService _firestore = FirestoreService();

  /// ✅ Create Order (with proper structure)
  Future<DocumentReference> createOrder(Map<String, dynamic> orderData) async {
    final ref = await _firestore.orders.add({
      'items': orderData['items'] ?? [],
      'total': orderData['total'] ?? 0,
      'status': 'pending',
      'orderNumber': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref;
  }

  /// ✅ Get Orders (typed stream)
  Stream<QuerySnapshot> getOrders() {
    return _firestore.orders.orderBy('createdAt', descending: true).snapshots();
  }

  /// ✅ Update Order Status
  Future<void> updateStatus(String id, String status) async {
    await _firestore.orders.doc(id).update({
      'status': status,
    });
  }

  /// ✅ Complete Order (bulk ready → completed)
  Future<void> completeReadyOrders() async {
    final snapshot =
        await _firestore.orders.where('status', isEqualTo: 'ready').get();
    for (var doc in snapshot.docs) {
      await doc.reference.update({'status': 'completed'});
    }
  }
}
