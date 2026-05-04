import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/firebase/order_service.dart';
import '../../services/firebase/product_service.dart';
import '../../widgets/app_navigation.dart';
import '../../widgets/receipt_dialog.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  late final ProductService _productService;
  late final OrderService _orderService;
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.ownerId.isNotEmpty) {
      _productService = ProductService(auth.ownerId);
      _orderService = OrderService(auth.ownerId);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<int?> _showQtyDialog(BuildContext context, String productName) async {
    int qty = 1;
    return showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Select Qty for $productName'),
        content: TextField(
          keyboardType: TextInputType.number,
          autofocus: true,
          onChanged: (value) {
            qty = int.tryParse(value) ?? 1;
          },
          decoration: const InputDecoration(
            labelText: 'Quantity',
            hintText: '1',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, qty),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  int _readyOrderCount(AsyncSnapshot snapshot) {
    if (!snapshot.hasData) return 0;
    return snapshot.data!.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['status'] == 'ready';
    }).length;
  }

  void _showReadyOrdersSheet(BuildContext context) {
    final rootContext = context;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                          final customerName =
                              data['customerName']?.toString().trim();
                          final orderLabel =
                              'Order #${data['orderNumber'] ?? orderId.substring(0, 6)}';
                          final items = List<Map<String, dynamic>>.from(
                            (data['items'] as List? ?? []).map(
                              (item) => Map<String, dynamic>.from(item as Map),
                            ),
                          );

                          final itemWidgets = <Widget>[];
                          for (final itemMap in items) {
                            final name = itemMap['name'] ?? 'Unknown';
                            final rawQty = itemMap['qty'] ??
                                itemMap['quantity'] ??
                                itemMap['count'] ??
                                itemMap['amount'] ??
                                1;
                            final qty = int.tryParse(rawQty.toString()) ?? 1;
                            itemWidgets.add(
                              Text('• $name x$qty',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            );
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Text(orderLabel,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 6),
                                  if (itemWidgets.isNotEmpty)
                                    ...itemWidgets
                                  else
                                    const Text('No items'),
                                  if (customerName != null &&
                                      customerName.isNotEmpty)
                                    Text('Customer: $customerName'),
                                  Text(
                                      'Rs ${((data['total'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)}'),
                                ],
                              ),
                              trailing: ElevatedButton(
                                onPressed: () async {
                                  Navigator.pop(sheetContext);
                                  await _orderService.updateStatus(
                                      orderId, 'completed');
                                  if (!rootContext.mounted) return;

                                  final orderNumber =
                                      (data['orderNumber'] as num?)?.toInt() ??
                                          0;
                                  final total =
                                      (data['total'] as num?)?.toDouble() ??
                                          0.0;
                                  final tendered =
                                      (data['tenderedAmount'] as num?)
                                              ?.toDouble() ??
                                          total;
                                  final change =
                                      (data['change'] as num?)?.toDouble() ??
                                          0.0;
                                  final createdAt =
                                      data['createdAt'] as Timestamp?;
                                  final date = createdAt != null
                                      ? '${createdAt.toDate().day}/${createdAt.toDate().month}/${createdAt.toDate().year} ${createdAt.toDate().hour.toString().padLeft(2, '0')}:${createdAt.toDate().minute.toString().padLeft(2, '0')}'
                                      : '';
                                  final servedBy = Provider.of<AuthProvider>(
                                          rootContext,
                                          listen: false)
                                      .role;

                                  await showDialog(
                                    context: rootContext,
                                    barrierDismissible: false,
                                    builder: (dialogContext) => ReceiptDialog(
                                      companyName: 'Orion POS',
                                      phone: '+92-317-7921817',
                                      email: 'info@orion.com',
                                      website: 'www.orion.com',
                                      servedBy: servedBy,
                                      customerName:
                                          customerName ?? 'Walk-in Customer',
                                      orderType: orderType,
                                      items: items,
                                      total: total,
                                      cash: tendered,
                                      change: change,
                                      tax: 0.0,
                                      paymentMethod:
                                          data['paymentMethod'] ?? 'cash',
                                      orderNo: 'ORDER-$orderNumber',
                                      date: date,
                                    ),
                                  );
                                },
                                child: const Text('Print & Complete'),
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

  int _crossAxisCount(double width) {
    if (width >= 1200) return 5;
    if (width >= 900) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, CartProvider>(
      builder: (context, auth, cart, child) {
        if (auth.user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/', (route) => false);
          });
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final user = auth.user!;
        final userEmail = user.email ?? 'No Email';
        final userName = user.displayName ?? userEmail.split('@').first;
        final photoUrl = user.photoURL;

        return Scaffold(
          drawer: AppNavigationDrawer(auth: auth, currentRoute: '/pos'),
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
              AppDrawerAvatarButton(
                photoUrl: photoUrl,
                userName: userName,
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) =>
                            setState(() => _searchQuery = v.toLowerCase()),
                        decoration: InputDecoration(
                          hintText: 'Search products...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: AppTheme.secondary.withOpacity(0.25),
                            ),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(24)),
                            borderSide: BorderSide(
                              color: AppTheme.primary,
                              width: 1.5,
                            ),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: StreamBuilder<List<Product>>(
                        stream: _productService.streamProducts,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return const Center(
                                child: Text('Error loading products'));
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(child: Text('No products'));
                          }

                          final products = snapshot.data!.where((product) {
                            return _searchQuery.isEmpty ||
                                product.name
                                    .toLowerCase()
                                    .contains(_searchQuery) ||
                                product.category
                                    .toLowerCase()
                                    .contains(_searchQuery);
                          }).toList();

                          if (products.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off,
                                      size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No products match "$_searchQuery"',
                                    style: TextStyle(
                                        fontSize: 18, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            );
                          }

                          // ✅ Responsive grid — adapts columns to screen width
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              final columns =
                                  _crossAxisCount(constraints.maxWidth);
                              return GridView.builder(
                                padding: const EdgeInsets.all(10),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  childAspectRatio: 1.1,
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
                                      onTap: () async {
                                        final qty = await _showQtyDialog(
                                            context, product.name);
                                        if (qty != null && qty > 0) {
                                          final productMap = product.toMap();
                                          productMap['qty'] = qty;
                                          await cart.addItem(productMap);
                                        }
                                      },
                                      child: Card(
                                        child: Padding(
                                          padding: const EdgeInsets.all(10),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  product.name,
                                                  style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 3,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                'Rs ${product.price.toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                SizedBox(
                                  height: 55,
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: cart.items.isEmpty
                                        ? null
                                        : () => Navigator.pushNamed(
                                            context, '/checkout'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(
                                          color: Colors.white70),
                                      disabledForegroundColor: Colors.white54,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                    ),
                                    child: const FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        'Proceed to Checkout',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                                if (cart.items.isNotEmpty)
                                  Positioned(
                                    top: -6,
                                    right: -6,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '${cart.items.length}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: StreamBuilder(
                              stream: _orderService.getOrders(),
                              builder: (context, snapshot) {
                                final readyCount = _readyOrderCount(snapshot);
                                return Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    SizedBox(
                                      width: double.infinity,
                                      height: 55,
                                      child: OutlinedButton(
                                        onPressed: () =>
                                            _showReadyOrdersSheet(context),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          side: const BorderSide(
                                              color: Colors.white70),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(24),
                                          ),
                                        ),
                                        child: const FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            'Ready Orders',
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (readyCount > 0)
                                      Positioned(
                                        top: -6,
                                        right: -6,
                                        child: Container(
                                          width: 18,
                                          height: 18,
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            '$readyCount',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
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
