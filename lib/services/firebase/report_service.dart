import 'package:cloud_firestore/cloud_firestore.dart';

class ReportService {
  final CollectionReference<Map<String, dynamic>> _orders =
      FirebaseFirestore.instance.collection('orders');

  /// Daily sales: List of {date: '2024-10-15', total: 1250}
  Stream<List<Map<String, dynamic>>> getDailySales() {
    return _orders.snapshots().map((snapshot) {
      final Map<String, double> dailyTotals = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final createdAt = data['createdAt'] as Timestamp?;
        if (createdAt != null) {
          final date =
              createdAt.toDate().toString().split(' ')[0]; // YYYY-MM-DD
          final total = (data['total'] as num?)?.toDouble() ?? 0.0;
          dailyTotals[date] = (dailyTotals[date] ?? 0.0) + total;
        }
      }
      return dailyTotals.entries
          .map((e) => {'date': e.key, 'total': e.value})
          .toList()
        ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
    });
  }

  /// Status stats: {pending: 3, ready: 2, completed: 1}
  Stream<Map<String, int>> getOrderStatusStats() {
    return _orders.snapshots().map((snapshot) {
      final stats = <String, int>{'pending': 0, 'ready': 0, 'completed': 0};
      for (var doc in snapshot.docs) {
        final status = doc.data()['status']?.toString() ?? 'unknown';
        stats[status] = (stats[status] ?? 0) + 1;
      }
      return stats;
    });
  }

  /// Today's revenue from all orders (today's date)
  Stream<double> getTodayRevenue() {
    return _orders.snapshots().map((snapshot) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      double total = 0.0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final createdAt = data['createdAt'] as Timestamp?;
        if (createdAt != null) {
          final orderDate = createdAt.toDate();
          final orderToday =
              DateTime(orderDate.year, orderDate.month, orderDate.day);
          if (orderToday.isAtSameMomentAs(today)) {
            total += (data['total'] as num?)?.toDouble() ?? 0.0;
          }
        }
      }
      return total;
    });
  }
}
