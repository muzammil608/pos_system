class Order {
  final String id;
  final int orderNumber;
  final List<Map<String, dynamic>> items;
  final double total;
  final String status;
  final DateTime createdAt;
  final String orderType;
  final String? tableNumber;
  final String? ownerId;

  Order({
    required this.id,
    required this.orderNumber,
    required this.items,
    required this.total,
    required this.status,
    required this.createdAt,
    required this.orderType,
    this.tableNumber,
    this.ownerId,
  });

  factory Order.fromMap(Map<String, dynamic> data, String id) {
    return Order(
      id: id,
      orderNumber: (data['orderNumber'] as num?)?.toInt() ?? 0,
      items: List<Map<String, dynamic>>.from(data['items'] ?? []),
      total: (data['total'] as num?)?.toDouble() ?? 0.0,
      status: data['status']?.toString() ?? 'pending',
      createdAt:
          DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
      orderType: data['orderType']?.toString() ?? 'takeaway',
      tableNumber: data['tableNumber']?.toString(),
      ownerId: data['ownerId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'items': items,
      'total': total,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'orderType': orderType,
      'orderNumber': orderNumber,
      if (tableNumber != null) 'tableNumber': tableNumber,
      if (ownerId != null) 'ownerId': ownerId,
    };
  }
}
