class Product {
  final String id;
  final String name;
  final double price;
  final String category;
  final String? imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    this.imageUrl,
  });

  factory Product.fromMap(Map<String, dynamic> data, String id) {
    final rawName = data['name'] ?? data['productName'] ?? data['title'];
    final rawPrice = data['price'] ?? data['unitPrice'] ?? data['amount'];
    final rawCategory = data['category'] ?? data['type'];

    final parsedName = rawName?.toString().trim() ?? '';
    final parsedCategory = rawCategory?.toString().trim() ?? '';

    final double? numericPrice = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse(rawPrice?.toString() ?? '');

    final String name = parsedName.isEmpty ? 'Unnamed Product' : parsedName;
    final double price = numericPrice ?? 0.0;
    final String category = parsedCategory.isEmpty ? 'Other' : parsedCategory;

    return Product(
      id: id,
      name: name,
      price: price,
      category: category,
      imageUrl: data['imageUrl']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'category': category,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }
}
