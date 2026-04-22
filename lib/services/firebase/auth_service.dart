import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirestoreService _firestore = FirestoreService();

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
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (result.user != null) {
      await _syncUserToFirestore(result.user!);
    }

    return result.user;
  }

  Future<User?> register(String email, String password, {String? name}) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = result.user;
    if (user != null && name != null && name.trim().isNotEmpty) {
      await user.updateDisplayName(name.trim());
      await user.reload();
    }

    if (_auth.currentUser != null) {
      await _syncUserToFirestore(_auth.currentUser!);
    }

    return _auth.currentUser;
  }

  Future<User?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      return null;
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final result = await _auth.signInWithCredential(credential);
    final user = result.user;

    if (user != null) {
      await _syncUserToFirestore(user);
    }

    return user;
  }

  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
