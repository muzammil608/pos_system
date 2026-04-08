import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/firebase/order_service.dart';
import '../../services/firebase/product_service.dart';
import '../../models/product_model.dart';
import '../../../services/printer/printer_service.dart';

class PosScreen extends StatelessWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    print("POS SCREEN RENDERED");

    final cart = Provider.of<CartProvider>(context);
    final orderService = OrderService();
    final productService = ProductService();

    final printerService = PrinterService();

    List<Map<String, dynamic>> originalCart = [];

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
              leading: const Icon(Icons.report),
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
      body: StreamBuilder<List<Product>>(
        stream: productService.streamProducts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No products - add in Firestore'));
          }

          final products = snapshot.data!;

          return Row(
            children: [
              /// 🟢 PRODUCTS GRID
              Expanded(
                flex: 2,
                child: GridView.builder(
                  padding: const EdgeInsets.all(10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemCount: products.length,
                  itemBuilder: (_, index) {
                    final product = products[index];

                    return GestureDetector(
                      onTap: () {
                        cart.addItem({
                          'name': product.name,
                          'price': product.price,
                        });
                      },
                      child: Card(
                        elevation: 3,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              product.name,
                              textAlign: TextAlign.center,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${product.price.toStringAsFixed(0)} Rs',
                              style: const TextStyle(fontSize: 16),
                            ),
                            Text(product.category,
                                style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              /// 🟡 CART PANEL
              Expanded(
                child: Column(
                  children: [
                    /// Cart Items
                    Expanded(
                      child: ListView.builder(
                        itemCount: cart.items.length,
                        itemBuilder: (_, i) {
                          final item = cart.items[i];

                          return ListTile(
                            title: Text(item['name'].toString()),
                            trailing: Text(item['price'].toString()),
                          );
                        },
                      ),
                    ),

                    /// Total
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "Total: ${cart.total}",
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),

                    /// ✅ Place Order Button
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: () async {
                          if (cart.items.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Cart is empty")),
                            );
                            return;
                          }

                          try {
                            final originalTotal = cart.total;
                            final orderRef = await orderService.createOrder({
                              'items': cart.items,
                              'total': originalTotal,
                            });

                            originalCart = List.from(cart.items);
                            cart.clear();

                            PrinterService.showReceiptDialog(context,
                                orderRef.id, originalCart, originalTotal);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      "Order #${orderRef.id.substring(0, 8)} printed & sent!"),
                                  duration: const Duration(seconds: 2)),
                            );

                            Navigator.pushNamed(context, '/kitchen');
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error: $e")),
                            );
                          }
                        },
                        child: const Text("Place Order"),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
