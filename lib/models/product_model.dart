import 'package:flutter/material.dart';
import '../core/utils/icon_helper.dart';

class Product {
  final String id;
  final String name;
  final double price;
  final String category;
  final String? imageUrl;
  final int? iconCodePoint;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    this.imageUrl,
    this.iconCodePoint,
  });

  /// Get the icon for this product (custom or default based on category)
  IconData get icon {
    if (iconCodePoint != null) {
      return IconHelper.fromCodePoint(iconCodePoint!);
    }
    return IconHelper.getDefaultIcon(category);
  }

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

    // Parse icon code point from Firestore data
    int? parsedIconCodePoint;
    if (data['iconCodePoint'] != null) {
      if (data['iconCodePoint'] is int) {
        parsedIconCodePoint = data['iconCodePoint'] as int;
      } else if (data['iconCodePoint'] is String) {
        parsedIconCodePoint = int.tryParse(data['iconCodePoint'] as String);
      }
    }

    return Product(
      id: id,
      name: name,
      price: price,
      category: category,
      imageUrl: data['imageUrl']?.toString(),
      iconCodePoint: parsedIconCodePoint,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'category': category,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (iconCodePoint != null) 'iconCodePoint': iconCodePoint,
    };
  }
}
