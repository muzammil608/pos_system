import 'package:flutter/material.dart';

import '../screens/auth/login_screen.dart';
import '../screens/pos/pos_screen.dart';
import '../screens/kitchen/kitchen_screen.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    '/': (_) => LoginScreen(),
    '/pos': (_) => PosScreen(),
    '/kitchen': (_) => KitchenScreen(),
  };
}
