import 'package:flutter/material.dart';
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
  bool _isLoading = false;

  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _goToRoleScreen(String role) {
    if (_navigated) return;
    _navigated = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      switch (role) {
        case 'admin':
          Navigator.pushReplacementNamed(context, '/admin');
          break;
        case 'cashier':
          Navigator.pushReplacementNamed(context, '/pos');
          break;
        case 'kitchen':
          Navigator.pushReplacementNamed(context, '/kitchen');
          break;
        default:
          Navigator.pushReplacementNamed(context, '/pos');
      }
    });
  }

  Future<void> _handleEmailLogin() async {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _isLoading = true;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);

    final AuthLoginResult? result = await auth.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;

    if (result == null) {
      final userRole = auth.role;
      Provider.of<CartProvider>(context, listen: false).clear();
      _goToRoleScreen(userRole);
    } else {
      setState(() {
        _emailError = result.emailError;
        _passwordError = result.passwordError;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _isLoading = true;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final String? error = await auth.signInWithGoogle();

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
    } else {
      final userRole = auth.role;
      Provider.of<CartProvider>(context, listen: false).clear();
      _goToRoleScreen(userRole);
    }
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required String? errorText,
    required void Function(String) onChanged,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    const errorColor = Color(0xFFD32F2F);
    const activeColor = Color(0xFF1E1E1E);
    const outlineColor = Color(0x661E1E1E);

    final bool isEmptyFieldError =
        errorText == "Please fill out required field!";

    final bool showErrorBelow = errorText != null && !isEmptyFieldError;
    final bool hasError = errorText != null;

    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.88),
        hintText: isEmptyFieldError ? errorText : hint,
        hintStyle: TextStyle(
          color: isEmptyFieldError
              ? errorColor
              : const Color(0xFF1E1E1E).withValues(alpha: 0.58),
          fontSize: 14,
          fontWeight: isEmptyFieldError ? FontWeight.w500 : FontWeight.normal,
        ),
        prefixIcon: Icon(
          icon,
          color: hasError ? errorColor : activeColor,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        errorText: showErrorBelow ? errorText : null,
        errorStyle: const TextStyle(
          color: errorColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: hasError ? errorColor : outlineColor,
            width: hasError ? 1.5 : 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: hasError ? errorColor : activeColor,
            width: 2.0,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: errorColor,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: errorColor,
            width: 2.0,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFFD61E),
              Color(0xFFFFC400),
              Color(0xFFFFB900),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: CustomPaint(
          painter: _FoodPatternPainter(),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, c) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: c.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          const SizedBox(height: 28),
                          const _BrandMark(),
                          const SizedBox(height: 8),
                          const Text(
                            "ORION",
                            style: TextStyle(
                              color: Color(0xFF171717),
                              fontSize: 58,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4,
                              height: 0.95,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 42,
                                child: Divider(
                                  color: Color(0xFF171717),
                                  thickness: 2,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  "PIZZA RESTAURANT",
                                  style: TextStyle(
                                    color: Color(0xFF171717),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 42,
                                child: Divider(
                                  color: Color(0xFF171717),
                                  thickness: 2,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 24),
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildField(
                                  controller: _emailController,
                                  hint: "Email",
                                  icon: Icons.email_outlined,
                                  errorText: _emailError,
                                  keyboardType: TextInputType.emailAddress,
                                  onChanged: (_) {
                                    if (_emailError != null) {
                                      setState(() {
                                        _emailError = null;
                                      });
                                    }
                                  },
                                ),
                                const SizedBox(height: 14),
                                _buildField(
                                  controller: _passwordController,
                                  hint: "Password",
                                  icon: Icons.lock_outline,
                                  errorText: _passwordError,
                                  obscure: true,
                                  onChanged: (_) {
                                    if (_passwordError != null) {
                                      setState(() {
                                        _passwordError = null;
                                      });
                                    }
                                  },
                                ),
                                const SizedBox(height: 18),
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed:
                                        _isLoading ? null : _handleEmailLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF171717),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
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
                                Row(
                                  children: const [
                                    Expanded(
                                      child: Divider(color: Color(0xFF171717)),
                                    ),
                                    Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 8),
                                      child: Text(
                                        "OR",
                                        style: TextStyle(
                                          color: Color(0xFF171717),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(color: Color(0xFF171717)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                IconButton(
                                  onPressed:
                                      _isLoading ? null : _handleGoogleLogin,
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.transparent,
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
                          const SizedBox(height: 36),
                          const Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 82,
                                    child: Divider(color: Color(0x80171717)),
                                  ),
                                  Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 10),
                                    child: Icon(
                                      Icons.local_pizza,
                                      color: Color(0xFF171717),
                                      size: 22,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 82,
                                    child: Divider(color: Color(0x80171717)),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Software By Orion Solutions",
                                style: TextStyle(
                                  color: Color(0xFF171717),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
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
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 118,
      height: 118,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF171717),
                width: 6,
              ),
            ),
          ),
          Transform.rotate(
            angle: -0.18,
            child: const Icon(
              Icons.local_pizza,
              color: Color(0xFF171717),
              size: 74,
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodPatternPainter extends CustomPainter {
  const _FoodPatternPainter();

  static const List<_PatternIcon> _icons = [
    _PatternIcon(Icons.local_pizza, Offset(0.08, 0.08), 60, -0.45),
    _PatternIcon(Icons.eco_outlined, Offset(0.68, 0.06), 48, 0.3),
    _PatternIcon(Icons.local_pizza, Offset(0.86, 0.12), 62, 0.42),
    _PatternIcon(Icons.circle_outlined, Offset(0.26, 0.17), 44, -0.25),
    _PatternIcon(Icons.local_dining, Offset(0.08, 0.28), 42, 0.15),
    _PatternIcon(Icons.eco_outlined, Offset(0.86, 0.30), 44, -0.12),
    _PatternIcon(Icons.local_pizza, Offset(0.14, 0.43), 60, -0.52),
    _PatternIcon(Icons.circle_outlined, Offset(0.72, 0.39), 42, 0.2),
    _PatternIcon(Icons.local_pizza, Offset(0.82, 0.61), 64, 0.42),
    _PatternIcon(Icons.eco_outlined, Offset(0.58, 0.65), 54, -0.24),
    _PatternIcon(Icons.circle_outlined, Offset(0.20, 0.71), 38, 0.18),
    _PatternIcon(Icons.local_pizza, Offset(0.08, 0.90), 58, -0.5),
    _PatternIcon(Icons.circle_outlined, Offset(0.75, 0.88), 40, 0.12),
    _PatternIcon(Icons.eco_outlined, Offset(0.88, 0.78), 44, 0.3),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    const color = Color(0x24171717);

    for (final icon in _icons) {
      final painter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icon.icon.codePoint),
          style: TextStyle(
            color: color,
            fontSize: icon.size,
            fontFamily: icon.icon.fontFamily,
            package: icon.icon.fontPackage,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final position = Offset(
        size.width * icon.position.dx,
        size.height * icon.position.dy,
      );

      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(icon.rotation);
      painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PatternIcon {
  const _PatternIcon(this.icon, this.position, this.size, this.rotation);

  final IconData icon;
  final Offset position;
  final double size;
  final double rotation;
}
