import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product_model.dart';
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
  final Map<String, String> _knownOrderStatuses = <String, String>{};
  StreamSubscription<QuerySnapshot>? _ordersSubscription;
  bool _isReadyAlertOpen = false;

  @override
  void initState() {
    super.initState();
    _listenForReadyOrders();
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    super.dispose();
  }

  void _listenForReadyOrders() {
    _ordersSubscription = _orderService.getOrders().listen((snapshot) async {
      if (!mounted || _isReadyAlertOpen) return;

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final currentStatus = data['status']?.toString() ?? 'unknown';
        final previousStatus = _knownOrderStatuses[doc.id];
        _knownOrderStatuses[doc.id] = currentStatus;

        if (currentStatus != 'ready') continue;
        if (previousStatus == null || previousStatus == 'ready') continue;

        _isReadyAlertOpen = true;

        final orderLabel =
            'Order #${data['orderNumber'] ?? doc.id.substring(0, 6)}';
        final customerName = data['customerName']?.toString().trim();

        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Order Ready To Serve'),
              content: Text(
                customerName != null && customerName.isNotEmpty
                    ? '$orderLabel for $customerName is ready to serve.'
                    : '$orderLabel is ready to serve.',
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );

        _isReadyAlertOpen = false;
        if (!mounted) return;
        break;
      }

      final activeIds = snapshot.docs.map((doc) => doc.id).toSet();
      _knownOrderStatuses.removeWhere((id, _) => !activeIds.contains(id));
    });
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
                const DrawerHeader(
                  decoration: BoxDecoration(color: Colors.purple),
                  child: Text(
                    'POS Menu',
                    style: TextStyle(color: Colors.white, fontSize: 20),
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
            title: const Text("POS"),
            actions: [
              IconButton(
                icon: const Icon(Icons.fact_check),
                tooltip: 'Ready Orders',
                onPressed: () => _showReadyOrdersSheet(context),
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
                              return GestureDetector(
                                onTap: () => cart.addItem({
                                  'name': product.name,
                                  'price': product.price,
                                }),
                                child: Card(
                                  elevation: 3,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          product.name,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        'Rs ${product.price.toStringAsFixed(0)}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      Text(
                                        product.category,
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ],
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
                      color: Colors.green,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: cart.items.isEmpty
                                  ? null
                                  : () =>
                                      Navigator.pushNamed(context, '/checkout'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              icon: const Icon(Icons.shopping_cart),
                              label: Text(
                                'Proceed to Checkout (${cart.items.length} items)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showReadyOrdersSheet(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white70),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              icon: const Icon(Icons.fact_check),
                              label: const Text('Ready Orders'),
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
