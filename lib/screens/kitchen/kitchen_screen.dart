import 'package:flutter/material.dart';
import '../../services/firebase/order_service.dart';

class KitchenScreen extends StatelessWidget {
  final OrderService _service = OrderService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Kitchen")),
      body: StreamBuilder(
        stream: _service.getOrders(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();

          final orders = snapshot.data.docs;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (_, i) {
              final order = orders[i];

              return Card(
                child: ListTile(
                  title: Text("Order ${order.id}"),
                  subtitle: Text(order['status']),
                  trailing: ElevatedButton(
                    onPressed: () {
                      _service.updateStatus(order.id, 'ready');
                    },
                    child: Text("Mark Ready"),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
