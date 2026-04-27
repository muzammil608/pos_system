import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';

class ProductGrid extends StatelessWidget {
  const ProductGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    final products = List.generate(12, (i) {
      return {
        'name': 'Item $i',
        'price': (i + 1) * 50.0,
      };
    });

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.2,
      ),
      itemCount: products.length,
      itemBuilder: (_, i) {
        final product = products[i];

        return GestureDetector(
          onTap: () => cart.addItem(product),
          child: Card(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(product['name'] as String),
                  Text("Rs ${product['price']}"),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
