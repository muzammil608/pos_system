import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/firebase/report_service.dart';

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
            /// Daily Sales Chart
            const Text('Daily Sales',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _reportService.getDailySales(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No sales data'));
                  }
                  final sales = snapshot.data!;
                  return LineChart(LineChartData(
                    lineBarsData: [
                      LineChartBarData(
                          spots: sales
                              .asMap()
                              .entries
                              .map((e) =>
                                  FlSpot(e.key.toDouble(), e.value['total']))
                              .toList())
                    ],
                  ));
                },
              ),
            ),
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
          ],
        ),
      ),
    );
  }
}
