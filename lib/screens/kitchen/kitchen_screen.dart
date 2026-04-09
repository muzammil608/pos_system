import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Kitchen Dashboard"),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false)
                  .login('demo@pos.com', 'password');
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
                colors: [Colors.purple, Colors.purpleAccent],
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
                              child: buildMetricCard('Pending', Colors.red,
                                  '${stats['pending']}')),
                          Expanded(
                              child: buildMetricCard(
                                  'Ready', Colors.orange, '${stats['ready']}')),
                          Expanded(
                              child: buildMetricCard('Completed', Colors.green,
                                  'Rs ${stats['completed']}')),
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
                        return const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: Text('Error loading orders')),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: Text('No orders')),
                        );
                      }

                      final orders = snapshot.data!.docs;

                      return Column(
                        children: orders.map((order) {
                          final data = order.data() as Map<String, dynamic>;
                          final id = order.id;
                          final status =
                              data['status']?.toString() ?? 'unknown';

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
                                  Text(
                                    'Rs ${(data['total'] as num?)?.toStringAsFixed(0) ?? '0'}',
                                    style: TextStyle(color: Colors.green[600]),
                                  ),
                                  Text(
                                    'Time: ${DateTime.now().toString().split(' ')[1].substring(0, 8)}',
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
                                        ? ElevatedButton(
                                            onPressed: () async {
                                              await _service.updateStatus(
                                                  id, 'completed');
                                            },
                                            child: const Text('Complete'),
                                          )
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
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/pos'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.point_of_sale),
          label: const Text('POS'),
        ),
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
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }
}
