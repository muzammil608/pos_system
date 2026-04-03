import 'package:flutter/material.dart';
import '../models/table_model.dart';

class TableProvider with ChangeNotifier {
  final List<TableModel> _tables = List.generate(
    12,
    (i) => TableModel(
      id: '$i',
      name: 'Table ${i + 1}',
      isOccupied: false,
    ),
  );

  List<TableModel> get tables => _tables;

  void toggleTable(int index) {
    _tables[index] = TableModel(
      id: _tables[index].id,
      name: _tables[index].name,
      isOccupied: !_tables[index].isOccupied,
    );
    notifyListeners();
  }
}
