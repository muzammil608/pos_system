import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';

class PosScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text("POS")),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
              ),
              itemCount: 10,
              itemBuilder: (_, index) {
                final product = {
                  'name': 'Item $index',
                  'price': 100.0,
                };

                return GestureDetector(
                  onTap: () => cart.addItem(product),
                  child: Card(
                    child: Center(child: Text(product['name'] as String)),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (_, i) {
                      return ListTile(
                        title: Text(cart.items[i]['name']),
                        trailing: Text("${cart.items[i]['price']}"),
                      );
                    },
                  ),
                ),
                Text("Total: ${cart.total}"),
                ElevatedButton(
                  onPressed: () {
                    Provider.of<OrderProvider>(context, listen: false)
                        .placeOrder(cart);
                  },
                  child: Text("Place Order"),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
