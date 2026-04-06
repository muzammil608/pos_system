import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/firebase/order_service.dart';
import '../../services/firebase/report_service.dart';
import '../../../widgets/status_donut_chart.dart';

class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key});

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> {
  final OrderService _service = OrderService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Kitchen Dashboard"),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Gradient Header
          Container(
            height: 80,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple, Colors.purpleAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const SafeArea(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.restaurant_menu, color: Colors.white, size: 32),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Kitchen Orders',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        Text('Live Status',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Metric Cards
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                            child: buildMetricCard('Pending', Colors.red, '0')),
                        Expanded(
                            child:
                                buildMetricCard('Ready', Colors.orange, '0')),
                        Expanded(
                            child: buildMetricCard(
                                'Completed', Colors.green, 'Rs 0')),
                      ],
                    ),
                  ),

                  // Donut Chart
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          'Order Status Distribution',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        const StatusDonutChart(),
                      ],
                    ),
                  ),

                  // Orders List
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: StreamBuilder(
                      stream: _service.getOrders(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError ||
                            !snapshot.hasData ||
                            snapshot.data!.docs.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.list_alt_outlined,
                                      size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text('No pending orders',
                                      style: TextStyle(
                                          fontSize: 16, color: Colors.grey)),
                                ],
                              ),
                            ),
                          );
                        }

                        final orders = snapshot.data!.docs;

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: orders.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final orderData =
                                orders[i].data() as Map<String, dynamic>;
                            final orderId = orders[i].id;
                            final status =
                                orderData['status']?.toString() ?? 'unknown';

                            return Card(
                              margin: EdgeInsets.zero,
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                title: Text("Order #$orderId",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Status: $status'),
                                    if (orderData['items'] != null)
                                      Text(
                                          '${orderData['items'].length} items • Rs${orderData['total']}'),
                                    Text(
                                        'Time: ${DateTime.now().toString().split(' ')[1].substring(0, 8)}'),
                                  ],
                                ),
                                trailing: SizedBox(
                                  width: 100,
                                  child: status == 'pending'
                                      ? ElevatedButton.icon(
                                          onPressed: () async {
                                            await _service.updateStatus(
                                                orderId, 'ready');
                                            if (mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content: Text(
                                                        'Order marked Ready')),
                                              );
                                            }
                                          },
                                          icon: const Icon(Icons.play_arrow,
                                              size: 16),
                                          label: const Text('Ready'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.orange,
                                            foregroundColor: Colors.white,
                                          ),
                                        )
                                      : status == 'ready'
                                          ? ElevatedButton.icon(
                                              onPressed: () async {
                                                await _service.updateStatus(
                                                    orderId, 'completed');
                                                if (mounted) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                        content: Text(
                                                            'Order Completed!')),
                                                  );
                                                }
                                              },
                                              icon: const Icon(Icons.check,
                                                  size: 16),
                                              label: const Text('Complete'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                foregroundColor: Colors.white,
                                              ),
                                            )
                                          : const Chip(
                                              label: Text('Done'),
                                              backgroundColor: Colors.green),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/pos'),
        backgroundColor: Colors.purple,
        icon: const Icon(Icons.point_of_sale, color: Colors.white),
        label: const Text('POS', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget buildMetricCard(String title, Color color, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.circle, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(value,
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }
}
