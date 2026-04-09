import 'package:flutter/material.dart';

import '../screens/auth/login_screen.dart';
import '../screens/pos/pos_screen.dart';
import '../screens/kitchen/kitchen_screen.dart';
import '../screens/tables/table_screen.dart';
import '../screens/reports/report_screen.dart';
import '../screens/reports/admin_dashboard_screen.dart';
import '../screens/products/product_management_screen.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    '/': (_) => LoginScreen(),
    '/pos': (_) => const PosScreen(),
    '/kitchen': (_) => KitchenScreen(),
    '/tables': (_) => TableScreen(),
    '/reports': (_) => ReportScreen(),
    '/admin': (_) => const AdminDashboardScreen(),
    '/products': (_) => const ProductManagementScreen(),
  };
}
