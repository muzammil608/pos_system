class ReceiptTemplate {
  static String generate(
    String orderId,
    List<Map<String, dynamic>> items,
    double total, {
    String orderType = 'takeaway',
    String? tableNumber,
  }) {
    String itemsStr = '';
    for (var item in items) {
      itemsStr +=
          '${item['name']} x1 ......... ${item['price'].toStringAsFixed(0)} Rs\n';
    }

    String typeLine = '';
    if (orderType == 'dine_in' && tableNumber != null) {
      typeLine = 'Table #$tableNumber';
    } else if (orderType == 'takeaway') {
      typeLine = 'TAKEAWAY ORDER';
    }

    return '''
=================================
    ORION PIZZA RESTAURANT
=================================
Order # $orderId
$typeLine

Items:
$itemsStr

Total: ${total.toStringAsFixed(0)} Rs

Thank you for visiting us!

Powered by Orion Solutions Pakistan
=================================
    ''';
  }
}
