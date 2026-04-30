import 'package:flutter/material.dart';

/// Helper class to map categories to icons and provide icon picker options
class IconHelper {
  // Fast food icons for the picker
  static const List<IconData> fastFoodIcons = [
    Icons.fastfood,
    Icons.local_pizza,
    Icons.lunch_dining,
    Icons.dinner_dining,
    Icons.bakery_dining,
    Icons.icecream,
    Icons.local_cafe,
    Icons.local_drink,
    Icons.emoji_food_beverage,
    Icons.coffee,
    Icons.brunch_dining,
    Icons.ramen_dining,
    Icons.takeout_dining,
    Icons.breakfast_dining,
    Icons.no_meals,
    Icons.kitchen,
    Icons.restaurant,
    Icons.restaurant_menu,
    Icons.set_meal,
  ];

  // Map categories to default icons
  static IconData getDefaultIcon(String category) {
    final lowerCategory = category.toLowerCase();

    if (lowerCategory.contains('pizza')) {
      return Icons.local_pizza;
    } else if (lowerCategory.contains('burger')) {
      return Icons.lunch_dining;
    } else if (lowerCategory.contains('drink') ||
        lowerCategory.contains('beverage') ||
        lowerCategory.contains('coffee') ||
        lowerCategory.contains('tea') ||
        lowerCategory.contains('juice')) {
      return Icons.local_cafe;
    } else if (lowerCategory.contains('dessert') ||
        lowerCategory.contains('ice cream') ||
        lowerCategory.contains('sweet')) {
      return Icons.icecream;
    } else if (lowerCategory.contains('bakery') ||
        lowerCategory.contains('bread') ||
        lowerCategory.contains('cake')) {
      return Icons.bakery_dining;
    } else if (lowerCategory.contains('rice') ||
        lowerCategory.contains('biryani') ||
        lowerCategory.contains('curry')) {
      return Icons.ramen_dining;
    } else if (lowerCategory.contains('chicken') ||
        lowerCategory.contains('meat')) {
      return Icons.dinner_dining;
    } else if (lowerCategory.contains('breakfast')) {
      return Icons.breakfast_dining;
    } else if (lowerCategory.contains('snack')) {
      return Icons.bakery_dining;
    } else if (lowerCategory.contains('fries') ||
        lowerCategory.contains('chips')) {
      return Icons.takeout_dining;
    }

    return Icons.fastfood;
  }

  // Get icon from code point
  static IconData fromCodePoint(int codePoint) {
    return IconData(codePoint, fontFamily: 'MaterialIcons');
  }
}
