import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../widgets/receipt_dialog.dart';
import 'receipt_template.dart';

class PrinterService {
  static Future<void> showReceiptDialog(
    BuildContext context,
    String orderId,
    List<Map<String, dynamic>> cartItems,
    double total,
  ) async {
    final receipt = ReceiptTemplate.generate(orderId, cartItems, total);

    if (kDebugMode) {
      print("🖨️ RECEIPT (Dialog + Console):");
      print(receipt);
      print("🖨️ END");
    }

    showDialog(
      context: context,
      builder: (ctx) => ReceiptDialog(
        orderId: orderId,
        receiptText: receipt,
      ),
    );
  }
}
