import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/auth_login_result.dart';
import '../services/firebase/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? user;
  Map<String, dynamic>? userData;
  StreamSubscription<User?>? _authSub;
  bool isLoading = false;

  String? _adminEmail;
  String? _adminPassword;

  String get role => userData?['role'] ?? 'cashier';
  bool get isAdmin => role == 'admin';
  bool get isCashier => role == 'cashier';
  bool get isKitchen => role == 'kitchen';

  AuthProvider() {
    _authService.ensurePersistence();
    user = _authService.currentUser;
    _loadUserRole(user);

    _authSub = _authService.authStateChanges.listen((updatedUser) {
      user = updatedUser;
      if (updatedUser != null) {
        _loadUserRole(updatedUser);
      } else {
        userData = null;
        _adminEmail = null;
        _adminPassword = null;
      }
      notifyListeners();
    });
  }

  Future<void> _loadUserRole(User? firebaseUser) async {
    if (firebaseUser == null) {
      userData = null;
      return;
    }

    try {
      final doc =
          await _firestore.collection('users').doc(firebaseUser.uid).get();

      if (doc.exists) {
        final data = doc.data()!;
        final isActive = data['isActive'] ?? true;
        if (!isActive) {
          await logout();
          return;
        }
        userData = data;
      } else {
        userData = {
          'role': 'cashier',
          'name': firebaseUser.displayName ?? '',
          'isActive': true,
        };
        await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .set(userData!);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user role: $e');
      userData = {'role': 'cashier'};
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<AuthLoginResult?> login(String email, String password) async {
    isLoading = true;
    notifyListeners();

    final trimmedEmail = email.trim();
    final trimmedPassword = password.trim();

    if (trimmedEmail.isEmpty || trimmedPassword.isEmpty) {
      isLoading = false;
      notifyListeners();

      return AuthLoginResult(
        emailError:
            trimmedEmail.isEmpty ? "Please fill out required field!" : null,
        passwordError:
            trimmedPassword.isEmpty ? "Please fill out required field!" : null,
      );
    }

    try {
      await _authService.login(trimmedEmail, trimmedPassword);
      await _loadUserRole(user);

      _adminEmail = trimmedEmail;
      _adminPassword = trimmedPassword;

      isLoading = false;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      isLoading = false;
      notifyListeners();

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
      notifyListeners();

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

      if (user != null) {
        await _firestore.collection('users').doc(user!.uid).set({
          'role': 'cashier',
          'name': name ?? email.split('@')[0],
          'email': email,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
        await _loadUserRole(user);
      }

      return null;
    } catch (e) {
      isLoading = false;
      notifyListeners();
      return AuthLoginResult(
        emailError: e.toString(),
      );
    }
  }

  Future<String?> signInWithGoogle() async {
    isLoading = true;
    notifyListeners();

    try {
      final result = await _authService.signInWithGoogle();

      if (result == null) {
        isLoading = false;
        notifyListeners();
        return 'Google sign in cancelled.';
      }

      await _loadUserRole(result);

      _adminEmail = result.email;
      _adminPassword = null;

      isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      isLoading = false;
      notifyListeners();
      return 'Google sign in failed. Please try again.';
    }
  }

  Future<void> logout() async {
    isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
      userData = null;
      _adminEmail = null;
      _adminPassword = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateUserRole(String userId, String newRole) async {
    if (!isAdmin) return false;

    try {
      await _firestore.collection('users').doc(userId).update({
        'role': newRole,
      });
      return true;
    } catch (e) {
      debugPrint('Error updating role: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> createEmployee({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    if (!isAdmin) {
      return {'success': false, 'error': 'Admin only'};
    }

    final adminUid = user!.uid;
    final adminEmail = _adminEmail;
    final adminPassword = _adminPassword;

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final newUid = credential.user!.uid;

      await _firestore.collection('users').doc(newUid).set({
        'role': role,
        'name': name,
        'email': email,
        'isActive': true,
        'createdBy': adminUid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (adminEmail != null && adminPassword != null) {
        try {
          await _authService.login(adminEmail, adminPassword);
          await _loadUserRole(_authService.currentUser);
        } catch (e) {
          debugPrint('Auto re-login failed: $e');
          return {
            'success': true,
            'email': email,
            'password': password,
            'relogin': false,
          };
        }
      }

      return {
        'success': true,
        'email': email,
        'password': password,
        'relogin': true,
      };
    } on FirebaseAuthException catch (e) {
      debugPrint('Error creating employee auth: $e');
      return {
        'success': false,
        'error': _authErrorMessage(e.code),
      };
    } catch (e) {
      debugPrint('Error creating employee: $e');
      return {
        'success': false,
        'error': 'Failed to create employee: $e',
      };
    }
  }

  String _authErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Email already in use';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password is too weak';
      default:
        return 'Failed to create employee';
    }
  }

  Future<bool> deleteEmployee(String userId) async {
    if (!isAdmin) return false;

    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': false,
        'deletedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error deleting employee: $e');
      return false;
    }
  }

  Stream<List<Map<String, dynamic>>> getEmployees() {
    if (!isAdmin) return Stream.value([]);
    return _firestore
        .collection('users')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .where((doc) {
              final data = doc.data();
              final role = data['role']?.toString() ?? '';
              final isActive = data['isActive'] ?? true;
              return (role == 'cashier' || role == 'kitchen') &&
                  isActive != false;
            })
            .map((doc) => {...doc.data(), 'id': doc.id})
            .toList());
  }
}
