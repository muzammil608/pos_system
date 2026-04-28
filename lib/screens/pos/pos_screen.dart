import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/firebase/order_service.dart';
import '../../services/firebase/product_service.dart';
import '../../widgets/receipt_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final ProductService _productService = ProductService();
  final OrderService _orderService = OrderService();

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
                              Text(
                                '• $name x$qty',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            );
                          }

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
                                  if (itemWidgets.isNotEmpty)
                                    ...itemWidgets
                                  else
                                    const Text('No items'),
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
                                  // 1. Close bottom sheet
                                  Navigator.pop(sheetContext);

                                  // 2. Complete the order FIRST
                                  await _orderService.updateStatus(
                                    orderId,
                                    'completed',
                                  );

                                  // 3. Show receipt using ReceiptDialog
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
                                  final servedBy =
                                      data['createdBy']?.toString() ??
                                          'Cashier';

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

  Widget _buildAvatar({
    required String? photoUrl,
    required String userName,
    double radius = 20,
    double fontSize = 16,
  }) {
    String? resolvedUrl;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      resolvedUrl = photoUrl.contains('googleusercontent.com')
          ? '${photoUrl.split('=').first}=s400'
          : photoUrl;
    }

    if (resolvedUrl != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppTheme.primary,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: resolvedUrl,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            placeholder: (context, url) =>
                _buildInitialAvatar(userName, radius, fontSize),
            errorWidget: (context, url, error) {
              debugPrint('Avatar load error: $error');
              return _buildInitialAvatar(userName, radius, fontSize);
            },
          ),
        ),
      );
    }
    return _buildInitialAvatar(userName, radius, fontSize);
  }

  Widget _buildInitialAvatar(String userName, double radius, double fontSize) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.secondary],
        ),
      ),
      child: Center(
        child: Text(
          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
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
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = auth.user!;
        final userEmail = user.email ?? 'No Email';
        final userName = user.displayName ?? userEmail.split('@').first;
        final photoUrl = user.photoURL;

        return Scaffold(
          drawer: Drawer(
            child: Column(
              children: [
                // ── Logo Header ──────────────────────────────────────────────
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
                        children: const [
                          Text(
                            'POS System',
                            style: TextStyle(
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

                // ── Navigation Menu (role-guarded) ──────────────────────────
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      if (auth.isAdmin)
                        ListTile(
                          leading: const Icon(Icons.analytics),
                          title: const Text('Admin Dashboard'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/admin');
                          },
                        ),
                      if (auth.isAdmin || auth.isKitchen)
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

                // ── Profile Section ──────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.15),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ✅ Google profile picture (or initial fallback)
                      _buildAvatar(
                        photoUrl: photoUrl,
                        userName: userName,
                        radius: 28,
                        fontSize: 22,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        userEmail,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                          fontFamily: 'monospace',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        auth.role.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.7,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Provider.of<AuthProvider>(
                                context,
                                listen: false,
                              ).logout();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.logout, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Logout',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
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
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => Scaffold.of(context).openDrawer(),
                  child: _buildAvatar(
                    photoUrl: photoUrl,
                    userName: userName,
                    radius: 18,
                    fontSize: 14,
                  ),
                ),
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
                              crossAxisCount: 2,
                              childAspectRatio: 0.75,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
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
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              product.name,
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold),
                                              textAlign: TextAlign.center,
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Text(
                                            'Rs ${product.price.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                                fontSize: 20,
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
