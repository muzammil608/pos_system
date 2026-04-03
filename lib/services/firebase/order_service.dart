import 'firestore_service.dart';

class OrderService {
  final FirestoreService _firestore = FirestoreService();

  Future<void> createOrder(Map<String, dynamic> orderData) async {
    await _firestore.orders.add(orderData);
  }

  Stream getOrders() {
    return _firestore.orders.orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> updateStatus(String id, String status) async {
    await _firestore.orders.doc(id).update({'status': status});
  }
}
