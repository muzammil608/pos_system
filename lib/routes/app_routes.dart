import 'package:flutter/material.dart';

import '../screens/auth/signup_screen.dart';
import '../screens/pos/pos_screen.dart';
import '../screens/kitchen/kitchen_screen.dart';
import '../screens/reports/report_screen.dart';
import '../screens/reports/admin_dashboard_screen.dart';
import '../screens/cart/checkout_screen.dart';
import '../screens/products/products_screen.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    '/pos': (_) => const PosScreen(),
    '/checkout': (_) => const CheckoutScreen(),
    '/kitchen': (_) => KitchenScreen(),
    '/reports': (_) => ReportScreen(),
    '/admin': (_) => const AdminDashboardScreen(),
    '/signup': (_) => const SignupScreen(),
    '/products': (_) => const ProductsScreen(),
  };
}
