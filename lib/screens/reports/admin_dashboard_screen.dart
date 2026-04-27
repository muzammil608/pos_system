import 'package:flutter/material.dart';
import '../../services/firebase/report_service.dart';
import '../../../widgets/status_donut_chart.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ReportService _reportService = ReportService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Dashboard")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Order Status Distribution',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const StatusDonutChart(size: 280),
            const SizedBox(height: 24),

            /// Order Status Stats
            const Text('Order Status',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            StreamBuilder<Map<String, int>>(
              stream: _reportService.getOrderStatusStats(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final stats = snapshot.data!;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: stats.entries
                      .map((e) => Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Text('${e.value}',
                                      style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold)),
                                  Text(e.key),
                                ],
                              ),
                            ),
                          ))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 24),

            const Text('Quick Actions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.inventory_2),
                label: const Text('Add Products'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.pushNamed(context, '/products'),
              ),
            ),
            const SizedBox(height: 24),

            const Text('Today\'s Revenue',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple)),
            const SizedBox(height: 16),
            StreamBuilder<double>(
              stream: _reportService.getTodayRevenue(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Card(
                    color: Colors.purple[50],
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }
                final revenue = snapshot.data!;
                return Card(
                  color: Colors.purple[50],
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Today\'s Revenue',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.purple[800])),
                            Text('Rs ${revenue.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple,
                                )),
                          ],
                        ),
                        Icon(Icons.trending_up, size: 48, color: Colors.purple),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
