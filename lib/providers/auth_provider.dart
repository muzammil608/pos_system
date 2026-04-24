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
    _authService.ensurePersistence(); // Fire and forget - persistence
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
    notifyListeners();

    try {
      await _authService.login(email, password);
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
        case 'invalid-email':
        case 'wrong-password':
        case 'invalid-credential':
        case 'user-disabled':
          return AuthLoginResult(
            emailError: 'invalid email or not registered',
          );
        default:
          return const AuthLoginResult(
            emailError: 'invalid email or not registered',
          );
      }
    } catch (e) {
      return const AuthLoginResult(
        emailError: 'invalid email or not registered',
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<AuthLoginResult?> register(String email, String password,
      {String? name}) async {
    isLoading = true;
    notifyListeners();

    try {
      await _authService.register(email, password, name: name);
      return null;
    } catch (e) {
      return AuthLoginResult(emailError: e.toString());
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> signInWithGoogle() async {
    isLoading = true;
    notifyListeners();

    try {
      final user = await _authService.signInWithGoogle();
      if (user == null) {
        return 'Google sign in cancelled.';
      }
      return null;
    } catch (e) {
      return 'Google sign in failed.';
    } finally {
      isLoading = false;
      notifyListeners();
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
