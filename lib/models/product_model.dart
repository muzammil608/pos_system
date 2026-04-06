class Product {
  final String id;
  final String name;
  final double price;
  final String category;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
  });

  factory Product.fromMap(Map<String, dynamic> data, String id) {
    String name = data['name']?.toString().trim() ?? 'Unknown';
    double price = (data['price'] as num?)?.toDouble() ?? 0.0;
    String category = data['category']?.toString().trim() ?? 'Other';

    return Product(
      id: id,
      name: name,
      price: price,
      category: category,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'category': category,
    };
  }
}
