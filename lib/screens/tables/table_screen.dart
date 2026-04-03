import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/table_provider.dart';

class TableScreen extends StatelessWidget {
  const TableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tables = Provider.of<TableProvider>(context).tables;

    return Scaffold(
      appBar: AppBar(title: const Text("Tables")),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
        ),
        itemCount: tables.length,
        itemBuilder: (_, i) {
          final table = tables[i];

          return Card(
            color: table.isOccupied ? Colors.red : Colors.green,
            child: Center(
              child: Text(
                table.name,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        },
      ),
    );
  }
}
