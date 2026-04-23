import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

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

  void _go() {
    if (_nav) return;
    _nav = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacementNamed(context, '/pos');
    });
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
                builder: (c, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
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
                                _field(Icons.person_outline, "Name", _name),
                                _field(Icons.email_outlined, "Email", _email),
                                _field(Icons.lock_outline, "Password", _pass,
                                    pass: true),
                                _field(Icons.lock_outline, "Confirm Password",
                                    _confirm,
                                    pass: true),
                                const SizedBox(height: 18),
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      final auth = Provider.of<AuthProvider>(
                                          context,
                                          listen: false);

                                      final err = await auth.register(
                                        _email.text.trim(),
                                        _pass.text.trim(),
                                        name: _name.text.trim(),
                                      );

                                      if (err == null) _go();
                                    },
                                    child: const Text("CREATE ACCOUNT"),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                IconButton(
                                  onPressed: () async {
                                    final auth = Provider.of<AuthProvider>(
                                        context,
                                        listen: false);

                                    final err = await auth.signInWithGoogle();

                                    if (err == null) _go();
                                  },
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

                          // 👇 SIMPLE LINK
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
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
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
          );
        },
      ),
    );
  }

  Widget _field(IconData icon, String hint, TextEditingController c,
      {bool pass = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        obscureText: pass,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
          filled: true,
          fillColor: Colors.white,
        ).copyWith(
          border: Theme.of(context).inputDecorationTheme.border,
          enabledBorder: Theme.of(context).inputDecorationTheme.enabledBorder,
          focusedBorder: Theme.of(context).inputDecorationTheme.focusedBorder,
        ),
      ),
    );
  }
}
