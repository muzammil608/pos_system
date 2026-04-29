import 'package:cloud_firestore/cloud_firestore.dart';

class ReportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection('orders');

  Stream<List<Map<String, dynamic>>> getDailySales() {
    return _orders.snapshots().map((snapshot) {
      final Map<String, double> dailyTotals = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final createdAt = data['createdAt'] as Timestamp?;
        if (createdAt != null) {
          final date = createdAt.toDate().toString().split(' ')[0];
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

  Stream<List<Map<String, dynamic>>> getOrdersByPeriod(String period) {
    return _orders.snapshots().map((snapshot) {
      final now = DateTime.now();
      final start = switch (period) {
        'weekly' => DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1)),
        'monthly' => DateTime(now.year, now.month),
        'yearly' => DateTime(now.year),
        _ => DateTime(now.year, now.month, now.day),
      };

      final orders = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final createdAt = data['createdAt'] as Timestamp?;
        if (createdAt == null) continue;

        final orderDate = createdAt.toDate();
        if (orderDate.isBefore(start) || orderDate.isAfter(now)) continue;

        orders.add({
          'id': doc.id,
          ...data,
          'createdAtDate': orderDate,
        });
      }

      orders.sort((a, b) {
        final aDate = a['createdAtDate'] as DateTime;
        final bDate = b['createdAtDate'] as DateTime;
        return bDate.compareTo(aDate);
      });

      return orders;
    });
  }
}
