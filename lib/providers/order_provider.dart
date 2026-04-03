import 'package:flutter/material.dart';
import '../services/firebase/order_service.dart';
import 'cart_provider.dart';

class OrderProvider with ChangeNotifier {
  final OrderService _orderService = OrderService();

  Future<void> placeOrder(CartProvider cart) async {
    final order = {
      'items': cart.items,
      'total': cart.total,
      'status': 'pending',
      'createdAt': DateTime.now().toIso8601String(),
    };

    await _orderService.createOrder(order);
    cart.clear();
  }
}
