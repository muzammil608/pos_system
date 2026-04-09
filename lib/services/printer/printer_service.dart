import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../widgets/receipt_dialog.dart';
import 'receipt_template.dart';

class PrinterService {
  static Future<void> showReceiptDialog(
    BuildContext context,
    int orderNumber,
    List<Map<String, dynamic>> cartItems,
    double total, {
    String orderType = 'takeaway',
    String? tableNumber,
  }) async {
    final receipt = ReceiptTemplate.generate(
      orderNumber.toString(),
      cartItems,
      total,
      orderType: orderType,
      tableNumber: tableNumber,
    );

    if (kDebugMode) {
      print("🖨️ RECEIPT #${orderNumber}:");
      print(receipt);
      print("🖨️ END");
    }

    showDialog(
      context: context,
      builder: (ctx) => ReceiptDialog(
        orderId: orderNumber.toString(),
        receiptText: receipt,
      ),
    );
  }
}
