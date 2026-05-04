import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase/order_service.dart';
import '../../services/firebase/report_service.dart';
import '../../widgets/app_navigation.dart';

class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key});

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> {
  late final OrderService _service;
  late final ReportService _reportService;

  final Set<String> _hiddenOrderIds = <String>{};
  final List<String> _visibleOrderIds = [];

  Stream<QuerySnapshot>? _ordersStream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.ownerId.isNotEmpty) {
      _service = OrderService(auth.ownerId);
      _reportService = ReportService(auth.ownerId);
      _ordersStream = _service.getOrders();
    }
  }

  @override
  void initState() {
    super.initState();
    // _ordersStream initialized in didChangeDependencies
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

        // Only admin and kitchen staff can access kitchen
        if (!auth.isAdmin && !auth.isKitchen) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/pos');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userRole = auth.role;
        final userEmail = auth.user?.email ?? 'No Email';
        final userName = auth.user?.displayName ?? userEmail.split('@').first;
        final photoUrl = auth.user?.photoURL;

        return Scaffold(
          backgroundColor: AppTheme.softBackground,
          drawer: AppNavigationDrawer(auth: auth, currentRoute: '/kitchen'),
          appBar: AppBar(
            title: Row(
              children: [
                const Icon(Icons.kitchen, size: 28),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Kitchen Dashboard",
                        style: TextStyle(fontSize: 20)),
                    Text(
                      userRole.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              AppDrawerAvatarButton(
                photoUrl: photoUrl,
                userName: userName,
              ),
            ],
          ),
          body: Column(
            children: [
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
                        Icon(Icons.restaurant_menu,
                            color: Colors.white, size: 32),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
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
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 120),
                  children: [
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
                                child: buildMetricCard('Pending',
                                    AppTheme.danger, '${stats['pending']}'),
                              ),
                              Expanded(
                                child: buildMetricCard('Ready', AppTheme.accent,
                                    '${stats['ready']}'),
                              ),
                              Expanded(
                                child: buildMetricCard(
                                    'Completed',
                                    AppTheme.secondary,
                                    '${stats['completed']}'),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _ordersStream,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                                  ConnectionState.waiting &&
                              !snapshot.hasData) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(
                                child: Text('Error: ${snapshot.error}'));
                          }
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: Text(
                                  'No orders yet',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.grey),
                                ),
                              ),
                            );
                          }

                          final docs = snapshot.data!.docs.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final status =
                                data['status']?.toString() ?? 'pending';
                            return !_hiddenOrderIds.contains(doc.id) &&
                                (status == 'pending' || status == 'ready');
                          }).toList();

                          _visibleOrderIds.clear();
                          for (final doc in docs) {
                            _visibleOrderIds.add(doc.id);
                          }

                          if (docs.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: Text(
                                  'All caught up! No active orders.',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.grey),
                                ),
                              ),
                            );
                          }

                          return Column(
                            children: docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final items = List<Map<String, dynamic>>.from(
                                  data['items'] ?? []);
                              final status =
                                  data['status']?.toString() ?? 'pending';
                              final orderNumber =
                                  (data['orderNumber'] as num?)?.toInt() ?? 0;
                              final tableNumber =
                                  data['tableNumber']?.toString();
                              final createdAt = data['createdAt'] as Timestamp?;
                              final orderType =
                                  data['orderType']?.toString() ?? 'takeaway';

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Order #$orderNumber',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: status == 'pending'
                                                  ? Colors.orange
                                                  : Colors.green,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              status.toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${orderType.toUpperCase()}${tableNumber != null ? ' - Table $tableNumber' : ''}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ...items.map((item) {
                                        final name =
                                            item['name']?.toString() ?? 'Item';
                                        final qty =
                                            (item['qty'] as num?)?.toInt() ??
                                                (item['quantity'] as num?)
                                                    ?.toInt() ??
                                                1;
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 2),
                                          child: Row(
                                            children: [
                                              Text(
                                                '$qty x',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(child: Text(name)),
                                            ],
                                          ),
                                        );
                                      }),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _formatTime(createdAt?.toDate()),
                                            style: TextStyle(
                                              color: Colors.grey[500],
                                              fontSize: 12,
                                            ),
                                          ),
                                          // Kitchen staff can only mark ready
                                          if (status == 'pending')
                                            ElevatedButton.icon(
                                              onPressed: () =>
                                                  _service.updateStatus(
                                                      doc.id, 'ready'),
                                              icon: const Icon(Icons.check,
                                                  size: 16),
                                              label: const Text('Mark Ready'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                foregroundColor: Colors.white,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
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
                for (final id in _visibleOrderIds) {
                  _hiddenOrderIds.add(id);
                }
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
      },
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
        children: [
          Icon(Icons.circle, color: color),
          const SizedBox(height: 8),
          Text(value,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(title,
              style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textPrimary.withValues(alpha: 0.7))),
        ],
      ),
    );
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '--:--:--';

    return '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}:'
        '${dateTime.second.toString().padLeft(2, '0')}';
  }
}
