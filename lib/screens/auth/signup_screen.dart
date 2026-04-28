import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../models/auth_login_result.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();

  bool _nav = false;
  bool _isLoading = false;
  String? _nameError;
  String? _emailError;
  String? _passError;
  String? _confirmError;

  void _go() {
    if (_nav) return;
    _nav = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacementNamed(context, '/pos');
    });
  }

  Future<void> _handleRegister() async {
    setState(() {
      _nameError = null;
      _emailError = null;
      _passError = null;
      _confirmError = null;
      _isLoading = true;
    });

    final name = _name.text.trim();
    final email = _email.text.trim();
    final pass = _pass.text.trim();
    final confirm = _confirm.text.trim();

    bool hasError = false;

    if (name.isEmpty) {
      _nameError = 'Name is required';
      hasError = true;
    }

    if (email.isEmpty) {
      _emailError = 'Email is required';
      hasError = true;
    } else if (!email.contains('@')) {
      _emailError = 'Enter a valid email';
      hasError = true;
    }

    if (pass.isEmpty) {
      _passError = 'Password is required';
      hasError = true;
    } else if (pass.length < 6) {
      _passError = 'Password must be at least 6 characters';
      hasError = true;
    }

    if (confirm.isEmpty) {
      _confirmError = 'Please confirm your password';
      hasError = true;
    } else if (pass != confirm) {
      _confirmError = 'Passwords do not match';
      hasError = true;
    }

    if (hasError) {
      setState(() => _isLoading = false);
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final AuthLoginResult? result = await auth.register(
      email,
      pass,
      name: name,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result == null) {
      _go();
    } else {
      setState(() {
        _emailError = result.emailError;
        _passError = result.passwordError;
      });
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _emailError = null;
      _passError = null;
      _isLoading = true;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final String? error = await auth.signInWithGoogle();

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
    } else {
      _go();
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
    const activeColor = Color(0xFF1976D2);
    const outlineColor = Color(0xFFBDBDBD);

    final bool hasError = errorText != null;

    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: hasError ? errorColor : Colors.grey,
          fontSize: 14,
        ),
        prefixIcon: Icon(
          icon,
          color: hasError ? errorColor : activeColor,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        errorText: errorText,
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
      body: Container(
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
            builder: (c, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    children: [
                      const SizedBox(height: 30),

                      Icon(Icons.person_add_alt_1_rounded,
                          size: 65,
                          color: Theme.of(context).colorScheme.onPrimary),

                      const SizedBox(height: 10),

                      Text(
                        "CREATE ACCOUNT",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // CARD
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 18),
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
                          children: [
                            _buildField(
                              controller: _name,
                              hint: "Name",
                              icon: Icons.person_outline,
                              errorText: _nameError,
                              onChanged: (_) {
                                if (_nameError != null) {
                                  setState(() => _nameError = null);
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildField(
                              controller: _email,
                              hint: "Email",
                              icon: Icons.email_outlined,
                              errorText: _emailError,
                              keyboardType: TextInputType.emailAddress,
                              onChanged: (_) {
                                if (_emailError != null) {
                                  setState(() => _emailError = null);
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildField(
                              controller: _pass,
                              hint: "Password",
                              icon: Icons.lock_outline,
                              errorText: _passError,
                              obscure: true,
                              onChanged: (_) {
                                if (_passError != null) {
                                  setState(() => _passError = null);
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildField(
                              controller: _confirm,
                              hint: "Confirm Password",
                              icon: Icons.lock_outline,
                              errorText: _confirmError,
                              obscure: true,
                              onChanged: (_) {
                                if (_confirmError != null) {
                                  setState(() => _confirmError = null);
                                }
                              },
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleRegister,
                                style: ElevatedButton.styleFrom(
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
                                        "CREATE ACCOUNT",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            IconButton(
                              onPressed:
                                  _isLoading ? null : _handleGoogleSignIn,
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

                      // Login link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an account? ",
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimary
                                    .withOpacity(0.8)),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/'),
                            child: Text(
                              "Login",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
