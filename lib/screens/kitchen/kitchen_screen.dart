import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase/order_service.dart';
import '../../services/firebase/report_service.dart';

class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key});

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> {
  final OrderService _service = OrderService();
  final ReportService _reportService = ReportService();
  final Set<String> _hiddenOrderIds = <String>{};
  final Set<String> _loadedOrderIds = <String>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softBackground,
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: AppTheme.primary),
              child: Text(
                'Kitchen Menu',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.point_of_sale),
              title: const Text('POS'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/pos');
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Admin Dashboard'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/admin');
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_restaurant),
              title: const Text('Tables'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/tables');
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text("Kitchen Dashboard"),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Provider.of<AuthProvider>(context, listen: false).logout();
              if (!context.mounted) return;
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // HEADER
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primary, AppTheme.secondary],
              ),
            ),
            child: const SafeArea(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.restaurant_menu, color: Colors.white, size: 32),
                    SizedBox(width: 12),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kitchen Orders',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Live Status',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // MAIN CONTENT
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 120),
              children: [
                // METRICS
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: StreamBuilder<Map<String, int>>(
                    stream: _reportService.getOrderStatusStats(),
                    builder: (context, snapshot) {
                      final stats = snapshot.data ??
                          {'pending': 0, 'ready': 0, 'completed': 0};

                      return Row(
                        children: [
                          Expanded(
                              child: buildMetricCard('Pending', AppTheme.danger,
                                  '${stats['pending']}')),
                          Expanded(
                              child: buildMetricCard(
                                  'Ready', AppTheme.accent, '${stats['ready']}')),
                          Expanded(
                              child: buildMetricCard('Completed', AppTheme.secondary,
                                  '${stats['completed']}')),
                        ],
                      );
                    },
                  ),
                ),

                // ORDERS LIST
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: StreamBuilder(
                    stream: _service.getOrders(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Text('Error loading orders\n${snapshot.error}'),
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: Text('No orders')),
                        );
                      }

                      final orders = snapshot.data!.docs
                          .where((order) => !_hiddenOrderIds.contains(order.id))
                          .toList();
                      orders.sort((a, b) {
                        final aData = a.data() as Map<String, dynamic>;
                        final bData = b.data() as Map<String, dynamic>;
                        final aCreatedAt = aData['createdAt'] as Timestamp?;
                        final bCreatedAt = bData['createdAt'] as Timestamp?;
                        final aMillis = aCreatedAt?.millisecondsSinceEpoch ?? 0;
                        final bMillis = bCreatedAt?.millisecondsSinceEpoch ?? 0;
                        return bMillis.compareTo(aMillis);
                      });
                      _loadedOrderIds
                        ..clear()
                        ..addAll(snapshot.data!.docs.map((order) => order.id));

                      if (orders.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: Text('No visible orders'),
                          ),
                        );
                      }

                      return Column(
                        children: orders.map((order) {
                          final data = order.data() as Map<String, dynamic>;
                          final id = order.id;
                          final status =
                              data['status']?.toString() ?? 'unknown';
                          final createdAt = data['createdAt'] as Timestamp?;
                          final createdTime = createdAt?.toDate();
                          final customerName =
                              data['customerName']?.toString().trim();
                          final paymentMethod =
                              data['paymentMethod']?.toString() ?? 'cash';
                          final orderType =
                              data['orderType']?.toString() ?? 'takeaway';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Text(
                                "Order #${data['orderNumber'] ?? id.substring(0, 6)}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              subtitle: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text('Status: $status'),
                                  if (data['items'] != null &&
                                      data['items'].isNotEmpty)
                                    Text(
                                      '${data['items'][0]['name']} (${data['items'].length} items)',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  if (customerName != null &&
                                      customerName.isNotEmpty)
                                    Text('Customer: $customerName'),
                                  Text(
                                      'Type: ${orderType.replaceAll('_', ' ')}'),
                                  Text(
                                      'Payment: ${paymentMethod.toUpperCase()}'),
                                  Text(
                                    'Rs ${(data['total'] as num?)?.toStringAsFixed(0) ?? '0'}',
                                    style: const TextStyle(color: AppTheme.primary),
                                  ),
                                  Text(
                                    'Time: ${_formatTime(createdTime)}',
                                  ),
                                ],
                              ),
                              trailing: SizedBox(
                                width: 100,
                                child: status == 'pending'
                                    ? ElevatedButton(
                                        onPressed: () async {
                                          await _service.updateStatus(
                                              id, 'ready');
                                        },
                                        child: const Text('Ready'),
                                      )
                                    : status == 'ready'
                                        ? const Chip(label: Text('Ready'))
                                        : const Chip(label: Text('Done')),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          setState(() {
            _hiddenOrderIds.addAll(_loadedOrderIds);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kitchen history removed from screen'),
            ),
          );
        },
        icon: const Icon(Icons.delete_sweep),
        label: const Text('Delete History'),
      ),
    );
  }

  Widget buildMetricCard(String title, Color color, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: color),
          const SizedBox(height: 8),
          Text(value,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textPrimary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '--:--:--';

    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }
}
