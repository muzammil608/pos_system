import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/auth_login_result.dart';
import '../services/firebase/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  User? user;
  StreamSubscription<User?>? _authSub;
  bool isLoading = false;

  AuthProvider() {
    _authService.ensurePersistence();
    user = _authService.currentUser;

    _authSub = _authService.authStateChanges.listen((updatedUser) {
      user = updatedUser;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<AuthLoginResult?> login(String email, String password) async {
    isLoading = true;

    final trimmedEmail = email.trim();
    final trimmedPassword = password.trim();

    if (trimmedEmail.isEmpty || trimmedPassword.isEmpty) {
      isLoading = false;

      return AuthLoginResult(
        emailError:
            trimmedEmail.isEmpty ? "Please fill out required field!" : null,
        passwordError:
            trimmedPassword.isEmpty ? "Please fill out required field!" : null,
      );
    }

    try {
      await _authService.login(trimmedEmail, trimmedPassword);

      isLoading = false;
      notifyListeners();

      return null;
    } on FirebaseAuthException catch (e) {
      isLoading = false;

      String? emailError;
      String? passwordError;

      switch (e.code) {
        case 'invalid-email':
          emailError = "Invalid email address";
          break;

        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          emailError = "Wrong credentials!";
          passwordError = "Wrong credentials!";
          break;

        case 'user-disabled':
          emailError = "This account has been disabled";
          break;

        case 'too-many-requests':
          emailError = "Too many attempts. Please try again later";
          break;

        default:
          emailError = "Login failed. Please try again";
          passwordError = "Login failed. Please try again";
      }

      return AuthLoginResult(
        emailError: emailError,
        passwordError: passwordError,
      );
    } catch (e) {
      isLoading = false;

      return AuthLoginResult(
        emailError: "An unexpected error occurred",
        passwordError: "An unexpected error occurred",
      );
    }
  }

  Future<AuthLoginResult?> register(
    String email,
    String password, {
    String? name,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      await _authService.register(email, password, name: name);
      return null;
    } catch (e) {
      return AuthLoginResult(
        emailError: e.toString(),
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> signInWithGoogle() async {
    isLoading = true;
    notifyListeners();

    try {
      final result = await _authService.signInWithGoogle();

      if (result == null) {
        isLoading = false;
        return 'Google sign in cancelled.';
      }

      isLoading = false;
      notifyListeners();

      return null;
    } catch (e) {
      isLoading = false;
      return 'Google sign in failed. Please try again.';
    }
  }

  Future<void> logout() async {
    isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
