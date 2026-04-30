import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
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

  // Flag to ignore auth state changes during employee creation
  bool _ignoringAuthChanges = false;

  String get role => userData?['role'] ?? 'cashier';
  bool get isAdmin => role == 'admin';
  bool get isCashier => role == 'cashier';
  bool get isKitchen => role == 'kitchen';

  AuthProvider() {
    _authService.ensurePersistence();
    user = _authService.currentUser;
    _loadUserRole(user);

    _authSub = _authService.authStateChanges.listen((updatedUser) {
      // Skip processing if we are in the middle of creating an employee
      if (_ignoringAuthChanges) return;

      user = updatedUser;
      if (updatedUser != null) {
        _loadUserRole(updatedUser);
      } else {
        userData = null;
        notifyListeners();
      }
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
      // ✅ Use the returned user directly from auth_service login
      final loggedInUser =
          await _authService.login(trimmedEmail, trimmedPassword);
      await _loadUserRole(loggedInUser);

      // ✅ Block deactivated (deleted) employees from logging in
      final isActive = userData?['isActive'] ?? true;
      if (!isActive) {
        await logout();
        isLoading = false;
        notifyListeners();
        return AuthLoginResult(
          emailError: "This account has been deactivated.",
          passwordError: "This account has been deactivated.",
        );
      }

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
    } finally {
      isLoading = false;
      notifyListeners();
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
    final adminUserData =
        Map<String, dynamic>.from(userData!); // snapshot admin data
    FirebaseApp? secondaryApp;

    try {
      // Pause the auth listener — any Firebase auth state changes triggered
      // by the secondary app will be completely ignored.
      _ignoringAuthChanges = true;

      secondaryApp = await Firebase.initializeApp(
        name: 'employeeCreation_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      // Create employee on secondary instance — primary admin session untouched
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final newUid = credential.user!.uid;

      // Sign out secondary immediately
      await secondaryAuth.signOut();

      // Write employee Firestore doc
      await _firestore.collection('users').doc(newUid).set({
        'role': role,
        'name': name,
        'email': email,
        'isActive': true,
        'createdBy': adminUid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'email': email,
        'password': password,
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
    } finally {
      // Clean up secondary app
      await secondaryApp?.delete();

      // Explicitly restore admin state in case anything changed
      user = _authService.currentUser;
      userData = adminUserData;

      // Resume auth listener
      _ignoringAuthChanges = false;

      notifyListeners();
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
