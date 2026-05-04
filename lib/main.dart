import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';

import 'routes/app_routes.dart';
import 'screens/landing_screen.dart';
import 'screens/auth/login_screen.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          debugPrint(
              '🔍 MAIN: roleLoaded=${auth.isRoleLoaded}, user=${auth.user?.uid}');

          // 1. LOADING STATE
          if (!auth.isRoleLoaded) {
            return const MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          // 2. NOT LOGGED IN → show screen (NO NAVIGATOR)
          if (auth.user == null) {
            return const MaterialApp(
              debugShowCheckedModeBanner: false,
              home: LoginScreen(),
            );
          }

          // 3. LOGGED IN → inject dependent providers
          return MultiProvider(
            providers: [
              ChangeNotifierProvider(
                create: (_) => CartProvider(),
              ),
              ChangeNotifierProvider(
                create: (_) => OrderProvider(auth.ownerId),
              ),
              ChangeNotifierProvider(
                create: (_) => ProductProvider(auth.ownerId),
              ),
            ],
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              home: const LandingScreen(),
              routes: AppRoutes.routes,
            ),
          );
        },
      ),
    );
  }
}
