import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firebase/report_service.dart';
import '../../../widgets/status_donut_chart.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_navigation.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late final ReportService _reportService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _reportService = ReportService(auth.ownerId);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        if (auth.user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Only admin can access
        if (!auth.isAdmin) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/pos');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userEmail = auth.user?.email ?? 'No Email';
        final userName = auth.user?.displayName ?? userEmail.split('@').first;
        final photoUrl = auth.user?.photoURL;

        return Scaffold(
          appBar: AppBar(
            title: const Text("Admin Dashboard"),
            backgroundColor: AppTheme.textPrimary,
            foregroundColor: Colors.white,
            actions: [
              AppDrawerAvatarButton(
                photoUrl: photoUrl,
                userName: userName,
              ),
            ],
          ),
          drawer: AppNavigationDrawer(
            auth: auth,
            currentRoute: '/admin',
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Order Status Distribution',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                StatusDonutChart(ownerId: auth.ownerId, size: 280),
                const SizedBox(height: 24),

                /// Order Status Stats
                const Text('Order Status',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                                        fontSize: 16,
                                        color: Colors.purple[800])),
                                Text('Rs ${revenue.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple,
                                    )),
                              ],
                            ),
                            Icon(Icons.trending_up,
                                size: 48, color: Colors.purple),
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
      },
    );
  }
}
