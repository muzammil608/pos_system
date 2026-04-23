import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/firebase/order_service.dart';
import '../../services/firebase/product_service.dart';
import '../../services/printer/printer_service.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final ProductService _productService = ProductService();
  final OrderService _orderService = OrderService();

  int _readyOrderCount(AsyncSnapshot snapshot) {
    if (!snapshot.hasData) return 0;

    return snapshot.data!.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['status'] == 'ready';
    }).length;
  }

  void _showReadyOrdersSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * 0.75,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Icon(Icons.fact_check),
                      SizedBox(width: 8),
                      Text(
                        'Cashier Ready Orders',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder(
                    stream: _orderService.getOrders(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('No ready orders'));
                      }

                      final readyOrders = snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return data['status'] == 'ready';
                      }).toList();
                      readyOrders.sort((a, b) {
                        final aData = a.data() as Map<String, dynamic>;
                        final bData = b.data() as Map<String, dynamic>;
                        final aCreatedAt = aData['createdAt'] as Timestamp?;
                        final bCreatedAt = bData['createdAt'] as Timestamp?;
                        final aMillis = aCreatedAt?.millisecondsSinceEpoch ?? 0;
                        final bMillis = bCreatedAt?.millisecondsSinceEpoch ?? 0;
                        return bMillis.compareTo(aMillis);
                      });

                      if (readyOrders.isEmpty) {
                        return const Center(child: Text('No ready orders'));
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: readyOrders.length,
                        itemBuilder: (context, index) {
                          final order = readyOrders[index];
                          final data = order.data() as Map<String, dynamic>;
                          final orderId = order.id;
                          final orderType =
                              data['orderType']?.toString() ?? 'takeaway';
                          final paymentMethod =
                              data['paymentMethod']?.toString() ?? 'cash';
                          final customerName =
                              data['customerName']?.toString().trim();
                          final orderLabel =
                              'Order #${data['orderNumber'] ?? orderId.substring(0, 6)}';
                          final items = List<Map<String, dynamic>>.from(
                            (data['items'] as List? ?? []).map(
                              (item) => Map<String, dynamic>.from(item as Map),
                            ),
                          );

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Text(
                                orderLabel,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 6),
                                  Text(
                                    items.isNotEmpty
                                        ? '${items.first['name']} (${items.length} items)'
                                        : 'No items',
                                  ),
                                  if (customerName != null &&
                                      customerName.isNotEmpty)
                                    Text('Customer: $customerName'),
                                  Text(
                                    'Rs ${((data['total'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)}',
                                  ),
                                ],
                              ),
                              trailing: ElevatedButton(
                                onPressed: () async {
                                  await PrinterService.showReceiptDialog(
                                    context,
                                    (data['orderNumber'] ?? orderId).toString(),
                                    items,
                                    (data['total'] as num?)?.toDouble() ?? 0.0,
                                    orderType: orderType,
                                    tableNumber:
                                        data['tableNumber']?.toString(),
                                    customerName: customerName,
                                    paymentMethod: paymentMethod,
                                    tenderedAmount:
                                        (data['tenderedAmount'] as num?)
                                                ?.toDouble() ??
                                            0.0,
                                    change:
                                        (data['change'] as num?)?.toDouble() ??
                                            0.0,
                                    servedBy: 'Cashier',
                                  );

                                  await _orderService.updateStatus(
                                    orderId,
                                    'completed',
                                  );
                                },
                                child: const Text('Complete'),
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        return Scaffold(
          drawer: Drawer(
            child: ListView(
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primary, AppTheme.secondary],
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(35),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'POS System',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Restaurant POS',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
                  leading: const Icon(Icons.kitchen),
                  title: const Text('Kitchen'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/kitchen');
                  },
                ),
              ],
            ),
          ),
          appBar: AppBar(
            title: const Text("POS"),
            actions: [
              StreamBuilder(
                stream: _orderService.getOrders(),
                builder: (context, snapshot) {
                  final readyCount = _readyOrderCount(snapshot);

                  return IconButton(
                    tooltip: 'Ready Orders',
                    onPressed: () => _showReadyOrdersSheet(context),
                    icon: Badge(
                      isLabelVisible: readyCount > 0,
                      label: Text('$readyCount'),
                      child: const Icon(Icons.notifications_active),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () async {
                  await Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  ).logout();
                  if (!context.mounted) return;
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/',
                    (route) => false,
                  );
                },
                tooltip: 'Logout',
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: StreamBuilder<List<Product>>(
                        stream: _productService.streamProducts,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (snapshot.hasError) {
                            return const Center(
                              child: Text('Error loading products'),
                            );
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(child: Text('No products'));
                          }

                          final products = snapshot.data!;
                          return GridView.builder(
                            padding: const EdgeInsets.all(10),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                            ),
                            itemCount: products.length,
                            itemBuilder: (_, index) {
                              final product = products[index];
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () {
                                    print('TAP FIRED: ${product.id}');
                                    cart.addItem({
                                      'id': product.id,
                                      ...product.toMap(),
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content:
                                              Text('TAP: ${product.name}')),
                                    );
                                  },
                                  child: Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(product.name,
                                              style: const TextStyle(
                                                  fontSize: 14)),
                                          const SizedBox(height: 4),
                                          Text(
                                              'Rs ${product.price.toStringAsFixed(0)}',
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 2),
                                          Text(
                                              'ID: ${product.id.substring(0, 6)}...',
                                              style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: AppTheme.primary,
                      child: Row(
                        children: [
                          Expanded(
                            child: Badge(
                              isLabelVisible: cart.items.isNotEmpty,
                              label: Text('${cart.items.length}'),
                              child: SizedBox(
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: cart.items.isEmpty
                                      ? null
                                      : () => Navigator.pushNamed(
                                          context, '/checkout'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.accent,
                                    foregroundColor: AppTheme.textPrimary,
                                    disabledBackgroundColor:
                                        AppTheme.accent.withValues(alpha: 0.35),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Proceed to Checkout',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SizedBox(
                              height: 55,
                              child: OutlinedButton(
                                onPressed: () => _showReadyOrdersSheet(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white70),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: StreamBuilder(
                                  stream: _orderService.getOrders(),
                                  builder: (context, snapshot) {
                                    final readyCount =
                                        _readyOrderCount(snapshot);
                                    return Text(
                                      readyCount > 0
                                          ? 'Ready Orders ($readyCount)'
                                          : 'Ready Orders',
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
