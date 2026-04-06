import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/table_provider.dart';

class TableScreen extends StatelessWidget {
  const TableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tables = Provider.of<TableProvider>(context).tables;

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.purple),
              child: Text('Tables Menu',
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
              leading: const Icon(Icons.point_of_sale),
              title: const Text('POS'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/pos');
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(title: const Text("Tables")),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
        ),
        itemCount: tables.length,
        itemBuilder: (_, i) {
          final table = tables[i];

          return GestureDetector(
            onTap: () => Provider.of<TableProvider>(context, listen: false)
                .toggleTable(i),
            child: Card(
              color: table.isOccupied ? Colors.red : Colors.green,
              child: Center(
                child: Text(
                  table.name,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/pos'),
        icon: const Icon(Icons.point_of_sale),
        label: const Text('POS'),
        tooltip: 'Back to POS',
      ),
    );
  }
}
