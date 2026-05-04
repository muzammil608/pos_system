import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart' show debugPrint;

import 'firestore_service.dart';

class AuthService {
  static bool _persistenceInitialized = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirestoreService _firestore = FirestoreService();

  /// Ensure auth persistence is set once (LOCAL persistence survives app kill/restart)
  Future<void> ensurePersistence() async {
    if (_persistenceInitialized) {
      debugPrint('🔍 PERSISTENCE-ALREADY: Skip');
      return;
    }
    try {
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
      _persistenceInitialized = true;
      debugPrint('🔍 PERSISTENCE-SUCCESS: LOCAL persistence enabled');
    } catch (e) {
      debugPrint('🔍 PERSISTENCE-ERROR: $e - Continuing without persistence');
      _persistenceInitialized = true; // Prevent retries
    }
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> _syncUserToFirestore(User user) async {
    final userRef = _firestore.users.doc(user.uid);
    final userSnap = await userRef.get();

    final data = <String, dynamic>{
      'email': user.email ?? '',
      'name': user.displayName ?? '',
      'photoUrl': user.photoURL ?? '',
      'isActive': true,
      'lastLoginAt': FieldValue.serverTimestamp(),
    };

    if (!userSnap.exists) {
      data['role'] = 'cashier';
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    await userRef.set(data, SetOptions(merge: true));
  }

  Future<User?> login(String email, String password) async {
    await ensurePersistence();

    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        await _syncUserToFirestore(result.user!);
      }
      return result.user;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> signInWithGoogle() async {
    await ensurePersistence();
    UserCredential result;

    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      result = await _auth.signInWithPopup(provider);
    } else {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      result = await _auth.signInWithCredential(credential);
    }

    final user = result.user;
    if (user != null) {
      await _syncUserToFirestore(user);
    }
    return user;
  }

  Future<void> logout() async {
    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }
    await _auth.signOut();
  }
}
