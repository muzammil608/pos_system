// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../models/auth_login_result.dart';

class _LoginColors {
  static const Color ink = Color(0xFF171717);
  static const Color error = Color(0xFFD32F2F);
  static const Color fieldBg = Color(0xE0FFFFFF);

  static const LinearGradient bg = LinearGradient(
    colors: [Color(0xFFFFD61E), Color(0xFFFFC400), Color(0xFFFFB900)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const Color scaffoldBg = Color(0xFFFFB900);
}

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
  bool _obscurePassword = true;

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

    if (result == null && auth.isRoleLoaded) {
      final userRole = auth.role;
      if (userRole.isEmpty || (userRole == 'cashier' && !auth.isCashier)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Role not configured. Please contact admin.')),
        );
        setState(() => _isLoading = false);
        return;
      }
      Provider.of<CartProvider>(context, listen: false).clear();
      _goToRoleScreen(userRole);
    } else if (result == null && !auth.isRoleLoaded) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _handleEmailLogin();
      });
    } else {
      setState(() {
        _emailError = result!.emailError;
        _passwordError = result!.passwordError;
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
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: _LoginColors.error),
      );
    } else if (!auth.isRoleLoaded) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _handleGoogleLogin();
      });
    } else {
      final userRole = auth.role;
      if (userRole.isEmpty || (userRole == 'cashier' && !auth.isCashier)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Role not configured. Please contact admin.')),
        );
        setState(() => _isLoading = false);
        return;
      }
      Provider.of<CartProvider>(context, listen: false).clear();
      _goToRoleScreen(userRole);
    }
  }

  Widget _buildEmailField() {
    final bool hasError = _emailError != null;
    final bool isEmptyError = _emailError == 'Please fill out required field!';
    return TextField(
      controller: _emailController,
      style: const TextStyle(fontSize: 15, color: _LoginColors.ink),
      decoration: _fieldDecoration(
        hint: 'Email address',
        icon: Icons.email_outlined,
        hasError: hasError,
        isEmptyError: isEmptyError,
        errorText: isEmptyError ? null : _emailError,
        suffixIcon: null,
      ),
    );
  }

  Widget _buildPasswordField() {
    final bool hasError = _passwordError != null;
    final bool isEmptyError =
        _passwordError == 'Please fill out required field!';
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: const TextStyle(fontSize: 15, color: _LoginColors.ink),
      decoration: _fieldDecoration(
        hint: 'Password',
        icon: Icons.lock_outline_rounded,
        hasError: hasError,
        isEmptyError: isEmptyError,
        errorText: isEmptyError ? null : _passwordError,
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: _LoginColors.ink.withOpacity(0.45),
            size: 20,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    required bool hasError,
    required bool isEmptyError,
    required String? errorText,
    required Widget? suffixIcon,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: _LoginColors.fieldBg,
      hintText: isEmptyError ? 'Please fill out required field!' : hint,
      hintStyle: TextStyle(
        color: isEmptyError
            ? _LoginColors.error
            : _LoginColors.ink.withOpacity(0.45),
        fontSize: 14,
        fontWeight: isEmptyError ? FontWeight.w600 : FontWeight.normal,
      ),
      prefixIcon: Icon(icon,
          color: hasError ? _LoginColors.error : _LoginColors.ink, size: 20),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      errorText: errorText,
      errorStyle: const TextStyle(
          color: _LoginColors.error, fontSize: 12, fontWeight: FontWeight.w600),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: hasError
              ? _LoginColors.error
              : _LoginColors.ink.withOpacity(0.18),
          width: hasError ? 1.5 : 1.0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
            color: hasError ? _LoginColors.error : _LoginColors.ink,
            width: 2.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _LoginColors.scaffoldBg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Container(
              // Background gradient and pattern covers everything
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              decoration: const BoxDecoration(gradient: _LoginColors.bg),
              child: CustomPaint(
                painter: _FoodPatternPainter(),
                child: Center(
                  // CENTERED CONTENT FOR WEB
                  child: ConstrainedBox(
                    // Limit width to 450px for a "card" feel on web, full width on mobile
                    constraints: const BoxConstraints(maxWidth: 450),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const _BrandMark(),
                          const SizedBox(height: 12),
                          const Text(
                            'ORION',
                            style: TextStyle(
                              color: _LoginColors.ink,
                              fontSize: 58,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4,
                              height: 0.95,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildDividerRow('PIZZA RESTAURANT'),
                          const SizedBox(height: 36),

                          // The Login Card
                          Container(
                            padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.5),
                                  width: 1.5),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Sign in',
                                  style: TextStyle(
                                    color: _LoginColors.ink,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                _buildEmailField(),
                                const SizedBox(height: 12),
                                _buildPasswordField(),
                                const SizedBox(height: 20),
                                _buildLoginButton(),
                                const SizedBox(height: 18),
                                _buildOrDivider(),
                                const SizedBox(height: 14),
                                _buildGoogleButton(),
                              ],
                            ),
                          ),

                          const SizedBox(height: 36),
                          _buildFooter(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _LoginColors.ink,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: _LoginColors.ink.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handleEmailLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white)))
              : const Text('LOGIN',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5)),
        ),
      ),
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: _LoginColors.ink.withOpacity(0.3))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('OR',
              style: TextStyle(
                  color: _LoginColors.ink.withOpacity(0.6),
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
        ),
        Expanded(child: Divider(color: _LoginColors.ink.withOpacity(0.3))),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _handleGoogleLogin,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.8),
          side: BorderSide(color: _LoginColors.ink.withOpacity(0.18)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/google_logo.png', height: 22, width: 22),
            const SizedBox(width: 10),
            const Text('Continue with Google',
                style: TextStyle(
                    color: _LoginColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildDividerRow(String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
            width: 42, child: Divider(color: _LoginColors.ink, thickness: 2)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(text,
              style: const TextStyle(
                  color: _LoginColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2)),
        ),
        const SizedBox(
            width: 42, child: Divider(color: _LoginColors.ink, thickness: 2)),
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
                width: 82,
                child: Divider(
                    color: _LoginColors.ink.withOpacity(0.3), thickness: 1)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Icon(Icons.local_pizza_rounded,
                  color: _LoginColors.ink, size: 20),
            ),
            SizedBox(
                width: 82,
                child: Divider(
                    color: _LoginColors.ink.withOpacity(0.3), thickness: 1)),
          ],
        ),
        const SizedBox(height: 8),
        const Text('Software By Orion Solutions',
            style: TextStyle(
                color: _LoginColors.ink,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ─── Brand Mark & Pattern Painter Classes (Remained same) ─────────────────────────
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
              border: Border.all(color: const Color(0xFF171717), width: 6),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 6))
              ],
            ),
          ),
          Transform.rotate(
              angle: -0.18,
              child: const Icon(Icons.local_pizza_rounded,
                  color: Color(0xFF171717), size: 74)),
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
    const color = Color(0x20171717);
    for (final icon in _icons) {
      final painter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icon.icon.codePoint),
          style: TextStyle(
              color: color,
              fontSize: icon.size,
              fontFamily: icon.icon.fontFamily,
              package: icon.icon.fontPackage),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final position =
          Offset(size.width * icon.position.dx, size.height * icon.position.dy);
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
