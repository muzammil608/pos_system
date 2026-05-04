import 'dart:async';
import 'dart:io' show TimeoutException;
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
  bool _roleLoaded = false;
  bool get isRoleLoaded => _roleLoaded;

  bool _ignoringAuthChanges = false;

  String get role => userData?['role']?.toString() ?? 'cashier';
  String? get currentUid => user?.uid;
  String get ownerId => (userData?['adminId'] as String?) ?? currentUid ?? '';
  bool get isAdmin => role == 'admin';
  bool get isCashier => role == 'cashier';
  bool get isKitchen => role == 'kitchen';

  AuthProvider() {
    debugPrint('🔍 AUTH-PROVIDER-INIT: Starting...');
    _authService.ensurePersistence();
    user = _authService.currentUser;
    debugPrint('🔍 AUTH-PROVIDER-CURRENT-USER: ${user?.uid ?? 'null'}');
    _loadUserRole(user);

    _authSub = _authService.authStateChanges.listen((updatedUser) {
      debugPrint('🔍 AUTH-STATE-CHANGE: ${updatedUser?.uid ?? 'null'}');
      if (_ignoringAuthChanges) return;

      user = updatedUser;
      if (updatedUser != null) {
        _loadUserRole(updatedUser);
      } else {
        userData = null;
        notifyListeners();
      }
    });
    debugPrint('🔍 AUTH-PROVIDER-INIT: Complete');
  }

  Future<void> _loadUserRole(User? firebaseUser) async {
    debugPrint('🔍 LOAD-ROLE-START: uid=${firebaseUser?.uid}');

    _roleLoaded = false;
    notifyListeners();

    if (firebaseUser == null) {
      debugPrint('🔍 LOAD-ROLE-NULL: No user');
      userData = null;
      _roleLoaded = true;
      notifyListeners();
      return;
    }

    try {
      // 10s timeout on Firestore read
      final docSnap = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get()
          .timeout(const Duration(seconds: 10), onTimeout: () {
        debugPrint('🔍 LOAD-ROLE-TIMEOUT: Firestore read timed out');
        throw TimeoutException(
            'Firestore timeout', const Duration(seconds: 10));
      });

      debugPrint('🔍 LOAD-ROLE-FETCHED: doc.exists=${docSnap.exists}');

      if (docSnap.exists) {
        final data = docSnap.data()!;
        final isActive = data['isActive'] ?? true;
        debugPrint('🔍 LOAD-ROLE-ACTIVE: isActive=$isActive');

        if (!isActive) {
          debugPrint('🔍 LOAD-ROLE-INACTIVE: Logging out inactive user');
          await logout();
          return;
        }
        userData = data;
      } else {
        // New user - default as admin, self-owned
        debugPrint('🔍 LOAD-ROLE-NEWUSER: Creating default admin profile');
        userData = {
          'role': 'admin',
          'name': firebaseUser.displayName ?? 'Admin',
          'adminId': firebaseUser.uid,
          'isActive': true,
        };
        await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .set(userData!, SetOptions(merge: true));
      }

      debugPrint(
          '🔍 LOAD-ROLE-SUCCESS: role=${userData!['role']}, ownerId=${userData!['adminId'] ?? firebaseUser.uid}');
      _roleLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('🔍 LOAD-ROLE-ERROR: $e');
      // Fallback: use current uid as ownerId, default role
      userData = {
        'role': 'cashier',
        'adminId': firebaseUser.uid,
        'isActive': true,
        'name': firebaseUser.displayName ?? 'User',
        '_fallback': true, // debug flag
      };
      debugPrint(
          '🔍 LOAD-ROLE-FALLBACK: ownerId=${firebaseUser.uid}, role=cashier');
      _roleLoaded = true;
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
      final loggedInUser =
          await _authService.login(trimmedEmail, trimmedPassword);
      await _loadUserRole(loggedInUser);
      // Wait a tick for roleLoaded to update
      await Future.delayed(const Duration(milliseconds: 100));

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
    final adminUserData = Map<String, dynamic>.from(userData!);
    FirebaseApp? secondaryApp;

    try {
      _ignoringAuthChanges = true;

      secondaryApp = await Firebase.initializeApp(
        name: 'employeeCreation_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final newUid = credential.user!.uid;

      await secondaryAuth.signOut();

      // ✅ Add adminId for employee ownership
      await _firestore.collection('users').doc(newUid).set({
        'role': role,
        'name': name,
        'email': email,
        'adminId': adminUid,
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
      await secondaryApp?.delete();

      user = _authService.currentUser;
      userData = adminUserData;

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
        .where('adminId', isEqualTo: currentUid)
        .snapshots()
        .map((snapshot) => snapshot.docs.where((doc) {
              final data = doc.data();
              final role = data['role']?.toString() ?? '';
              final isActive = data['isActive'] ?? true;
              return (role == 'cashier' || role == 'kitchen') &&
                  isActive != false;
            }).map((doc) {
              final data = doc.data();

              // ✅ Fix: ensure name is never null or empty string,
              //    which would cause RangeError(index) in _avatarGradient
              final rawName = (data['name']?.toString() ?? '').trim();
              final safeName = rawName.isEmpty ? 'Unknown' : rawName;

              return {
                ...data,
                'id': doc.id,
                'name': safeName,
              };
            }).toList());
  }
}
