import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/firebase/product_service.dart';
import '../../models/product_model.dart';
import '../../services/firebase/order_service.dart';
import '../../../services/printer/printer_service.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  String _orderType = 'takeaway';
  String? _tableNumber;

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        final productService = ProductService();
        final orderService = OrderService();

        return Scaffold(
          drawer: Drawer(
            child: ListView(
              children: [
                const DrawerHeader(
                  decoration: BoxDecoration(color: Colors.purple),
                  child: Text('POS Menu',
                      style: TextStyle(color: Colors.white, fontSize: 20)),
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
          appBar: AppBar(title: const Text("POS")),
          body: Column(
            children: [
              // Order Options Bar
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _orderType,
                        decoration: const InputDecoration(
                          labelText: 'Order Type *',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'takeaway', child: Text('Takeaway')),
                          DropdownMenuItem(
                              value: 'dine_in', child: Text('Dine In')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _orderType = value ?? 'takeaway';
                            if (value != 'dine_in') _tableNumber = null;
                          });
                        },
                      ),
                    ),
                    if (_orderType == 'dine_in') ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          value: _tableNumber,
                          decoration: const InputDecoration(
                            labelText: 'Table *',
                            border: OutlineInputBorder(),
                          ),
                          isExpanded: true,
                          hint: const Text('1-20'),
                          items: List.generate(
                              20,
                              (i) => DropdownMenuItem(
                                    value: '${i + 1}',
                                    child: Text('T${i + 1}'),
                                  )),
                          onChanged: (value) =>
                              setState(() => _tableNumber = value),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    // Products Grid
                    Expanded(
                      child: StreamBuilder<List<Product>>(
                        stream: productService.streamProducts,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
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
                                              fontWeight: FontWeight.bold),
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
                    // Cart with Edit/Delete
                    Container(
                      width: 340,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        border:
                            Border(left: BorderSide(color: Colors.grey[300]!)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                const Icon(Icons.shopping_cart,
                                    color: Colors.blue),
                                const SizedBox(width: 8),
                                Text(
                                  'Cart (${cart.items.length})',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: cart.items.length,
                              itemBuilder: (_, i) {
                                final item = cart.items[i];
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  child: ListTile(
                                    dense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 4),
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.blue.shade100,
                                      child: Text('${i + 1}'),
                                    ),
                                    title: Text(
                                      item['name'].toString(),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                        'Rs ${item['price'].toStringAsFixed(0)}'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit,
                                              color: Colors.orange, size: 20),
                                          onPressed: () {
                                            _showEditDialog(
                                                context, i, item, cart);
                                          },
                                          tooltip: 'Edit',
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red, size: 20),
                                          onPressed: () => cart.removeItem(i),
                                          tooltip: 'Delete',
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          // Total & Order Button
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border(
                                  top: BorderSide(color: Colors.grey[300]!)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Total:',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold)),
                                    Text(
                                      'Rs ${cart.total.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: cart.items.isEmpty ||
                                            (_orderType == 'dine_in' &&
                                                _tableNumber == null)
                                        ? null
                                        : () => _placeOrder(
                                            context, cart, orderService),
                                    icon: const Icon(Icons.send),
                                    label: const Text('Place Order'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
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
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, int index,
      Map<String, dynamic> item, CartProvider cart) {
    final nameController = TextEditingController(text: item['name']);
    final priceController =
        TextEditingController(text: item['price'].toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              cart.items[index] = {
                'name': nameController.text,
                'price': double.tryParse(priceController.text) ?? 0,
              };
              cart.notifyListeners();
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _placeOrder(BuildContext context, CartProvider cart,
      OrderService orderService) async {
    if (_orderType == 'dine_in' && _tableNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select table for Dine In')),
      );
      return;
    }

    try {
      final originalTotal = cart.total;
      await orderService.createOrder(
        items: List.from(cart.items),
        total: originalTotal,
        orderType: _orderType,
        tableNumber: _tableNumber,
      );
      cart.clear();

      final orderRef = await orderService.createOrder(
        items: List.from(cart.items),
        total: originalTotal,
        orderType: _orderType,
        tableNumber: _tableNumber,
      );
      cart.clear();

      await PrinterService.showReceiptDialog(
        context,
        orderRef.id.hashCode.abs() % 1000 + 1, // temp until sequential
        List.from(cart.items),
        originalTotal,
        orderType: _orderType,
        tableNumber: _tableNumber,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '✅ $_orderType${_tableNumber != null ? ' Table $_tableNumber' : ''}')),
      );

      Navigator.pushNamed(context, '/kitchen');
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
