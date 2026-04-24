import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../models/auth_login_result.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _navigated = false;
  AuthLoginResult? _loginResult;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _goToPos() {
    if (_navigated) return;
    _navigated = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/pos');
    });
  }

  Future<void> _handleEmailLogin() async {
    // Clear previous errors
    setState(() {
      _loginResult = null;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);

    final result = await auth.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _loginResult = result;
    });

    if (result == null) {
      Provider.of<CartProvider>(context, listen: false).clear();
      _goToPos();
    }
  }

  Future<void> _handleGoogleLogin() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final error = await auth.signInWithGoogle();

    if (!mounted) return;

    setState(() {
      _loginResult = null; // Clear email/password errors on Google attempt
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    });

    if (error == null) {
      Provider.of<CartProvider>(context, listen: false).clear();
      _goToPos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary,
                  AppTheme.secondary,
                  AppTheme.accent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, c) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: c.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 30),

                            Icon(
                              Icons.account_circle_rounded,
                              size: 70,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),

                            const SizedBox(height: 12),

                            Text(
                              "POS SYSTEM",
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),

                            const SizedBox(height: 30),

                            // CARD
                            Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 18),
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.12),
                                    blurRadius: 25,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // EMAIL FIELD - UPDATED ✅
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    onChanged: (_) =>
                                        setState(() => _loginResult = null),
                                    decoration: InputDecoration(
                                      hintText: "Email",
                                      prefixIcon: Icon(
                                        Icons.email_outlined,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                      // ✅ Shows "invalid email or not registered"
                                      errorText: _loginResult?.emailError,
                                      errorStyle: TextStyle(
                                        color: Colors.red[400],
                                        fontSize: 13,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter email';
                                      }
                                      if (!value.contains('@')) {
                                        return 'Please enter valid email';
                                      }
                                      return null;
                                    },
                                  ),

                                  const SizedBox(height: 14),

                                  // PASSWORD FIELD - UPDATED ✅
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: true,
                                    onChanged: (_) =>
                                        setState(() => _loginResult = null),
                                    decoration: InputDecoration(
                                      hintText: "Password",
                                      prefixIcon: Icon(
                                        Icons.lock_outline,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                      // ✅ Shows same custom error
                                      errorText: _loginResult?.emailError,
                                      errorStyle: TextStyle(
                                        color: Colors.red[400],
                                        fontSize: 13,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter password';
                                      }
                                      return null;
                                    },
                                  ),

                                  const SizedBox(height: 18),

                                  SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: ElevatedButton(
                                      onPressed: auth.isLoading
                                          ? null
                                          : _handleEmailLogin,
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: auth.isLoading
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(
                                                  Colors.white,
                                                ),
                                              ),
                                            )
                                          : const Text(
                                              "LOGIN",
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // -------- OR DIVIDER --------
                                  Row(
                                    children: const [
                                      Expanded(child: Divider()),
                                      Padding(
                                        padding:
                                            EdgeInsets.symmetric(horizontal: 8),
                                        child: Text("OR"),
                                      ),
                                      Expanded(child: Divider()),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  IconButton(
                                    onPressed: auth.isLoading
                                        ? null
                                        : _handleGoogleLogin,
                                    style: IconButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(context).colorScheme.surface,
                                      padding: const EdgeInsets.all(12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    icon: Image.asset(
                                      'assets/images/google_logo.png',
                                      height: 28,
                                      width: 28,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "New here? ",
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary
                                        .withOpacity(0.8),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () =>
                                      Navigator.pushNamed(context, '/signup'),
                                  child: Text(
                                    "Create account",
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const Spacer(),

                            // -------- BOTTOM TEXT ONLY --------
                            const Column(
                              children: [
                                Text(
                                  "Software By Orion Solutions",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                SizedBox(height: 20),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
