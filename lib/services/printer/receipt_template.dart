class ReceiptTemplate {
  static String generate(
      String orderId, List<Map<String, dynamic>> items, double total) {
    String itemsStr = '';
    for (var item in items) {
      itemsStr +=
          '${item['name']} x1 ......... ${item['price'].toStringAsFixed(0)} Rs\n';
    }

    return '''
=================================
    ORION PIZZA RESTAURANT
=================================
Order # $orderId

Items:
$itemsStr

Total: ${total.toStringAsFixed(0)} Rs

Thank you for visiting us!

Powered by Orion Solutions Pakistan
=================================
    ''';
  }
}
