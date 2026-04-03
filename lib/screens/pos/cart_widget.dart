import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';

class CartWidget extends StatelessWidget {
  const CartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: cart.items.length,
            itemBuilder: (_, i) {
              final item = cart.items[i];

              return ListTile(
                title: Text(item['name']),
                subtitle: Text("Rs ${item['price']}"),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => cart.removeItem(i),
                ),
              );
            },
          ),
        ),
        const Divider(),
        Text("Total: Rs ${cart.total}", style: const TextStyle(fontSize: 18)),
      ],
    );
  }
}
