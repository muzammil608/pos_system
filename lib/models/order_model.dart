class Order {
  final String id;
  final List<Map<String, dynamic>> items;
  final double total;
  final String status;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.items,
    required this.total,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'items': items,
      'total': total,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
